bool startupVideoFinished(Object? time, Object? duration) =>
    time is num && duration is num && time.isFinite && duration.isFinite &&
    duration >= 6 && duration <= 6.1 && time >= duration;

/// Fit the complete video inside any phone viewport without cropping/stretching.
/// Unused space has a matching neutral background; original bytes are unchanged.
String startupVideoHtml(String originalBase64) => '''
<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<style>
html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#f7f7f7}
video{position:fixed;inset:0;width:100vw;height:100vh;object-fit:contain;object-position:center;background:#f7f7f7;pointer-events:none}
</style></head><body>
<video id="intro" playsinline webkit-playsinline muted preload="auto" disablepictureinpicture
 src="data:video/mp4;base64,$originalBase64"></video>
<script>
const video=document.getElementById('intro');
let paused=true;
let notified=false;
function notify(name,args){
  if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler(name,...args);
}
video.addEventListener('ended',()=>{
  if(notified) return;
  notified=true;
  notify('startupVideoEnded',[video.currentTime,video.duration]);
});
video.addEventListener('error',()=>notify('startupVideoError',[]));
window.atStartupPause=()=>{paused=true;video.pause();};
window.atStartupResume=()=>{
  paused=false;video.muted=true;video.playbackRate=1;
  if(video.ended || notified) return;
  video.play().catch(()=>{if(!paused)notify('startupVideoError',[]);});
};
</script></body></html>
''';
