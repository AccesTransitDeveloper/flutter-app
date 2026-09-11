//
//  NotificationService.swift
//  NotificationService
//
//  Created by urvish kaneriya on 13/03/26.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Extract image URL from FCM payload
        if let fcmOptions = request.content.userInfo["fcm_options"] as? [String: Any],
           let imageUrl = fcmOptions["image"] as? String,
           let url = URL(string: imageUrl) {
            downloadImageFrom(url: url) { attachment in
                if let attachment = attachment {
                    bestAttemptContent.attachments = [attachment]
                }
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadImageFrom(url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, _, error) in
            guard let downloadedUrl = downloadedUrl, error == nil else {
                completion(nil)
                return
            }

            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let tmpFile = tmpDir.appendingPathComponent(url.lastPathComponent)

            try? FileManager.default.removeItem(at: tmpFile)
            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: tmpFile)
                let attachment = try UNNotificationAttachment(
                    identifier: url.lastPathComponent,
                    url: tmpFile,
                    options: nil
                )
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
