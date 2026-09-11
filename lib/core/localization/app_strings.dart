import 'dart:convert';
import '../../models/string_object.dart';
import '../constants/app_constants.dart';
import 'local_strings.dart';

/// Global singleton for API strings (like appStr in Kotlin)
AppStrings appStr = AppStrings();

/// Current business type for string resolution (like businessTypeForString in Kotlin)
int businessTypeForString = BusinessType.taxi;

/// Holds all string values from API
class AppStrings {
  // App
  dynamic appName;

  // Buttons
  dynamic buttonEmail;
  dynamic buttonNext;
  dynamic buttonContinue;
  dynamic buttonContinueWithGoogle;
  dynamic buttonContinueWithApple;
  dynamic buttonContinueWithEmail;
  dynamic buttonResendOtp;
  dynamic buttonForgotPassword;

  // Hints
  dynamic hintPhoneNumber;
  dynamic hintFirstName;
  dynamic hintLastName;
  dynamic hintEmailExample;
  dynamic hintPassword;
  dynamic hintNumberExample;
  dynamic hintEnterPassword;
  dynamic hintConfirmPassword;

  // Headings
  dynamic headingWhatIsYourName;
  dynamic headingAcceptTermsAndReviewPrivacyNotice;
  dynamic headingLegal;
  dynamic descriptionTermsConditions;
  dynamic descriptionPrivacyPolicy;
  dynamic headingWhatIsYourEmailAddress;
  dynamic headingCreatePassword;
  dynamic headingResetPassword;
  dynamic headingVerifyAccount;
  dynamic headingEnterYourMobileNumber;
  dynamic headingConnectingNearbyDrivers;

  // Descriptions
  dynamic descriptionLetUsKnowHowToProperlyAddressYou;
  dynamic descriptionYouWillUseThisNumber;
  dynamic descriptionVerificationCodeSendToNumber;
  dynamic descriptionYouWillUseThisEmail;
  dynamic descriptionIAgree;
  dynamic descriptionAgreeTerms;
  dynamic descriptionEnterOtpSentTo;
  dynamic descriptionResendPhoneCode;
  dynamic descriptionResendEmailCode;
  dynamic descriptionEmail;
  dynamic descriptionPhone;
  dynamic descriptionPassword;
  dynamic descriptionTermsOfUse;
  dynamic descriptionPrivacyNotice;
  dynamic descriptionChangedYourMobileNumber;
  dynamic descriptionChangedYourEmailAddress;
  dynamic descriptionLoginWithOtpInstead;
  dynamic descriptionLoginWithPasswordInstead;
  dynamic descriptionEnterPasswordFor;
  dynamic descriptionByContinuingYouAgree;

  // Ride Types
  dynamic descriptionNormal;
  dynamic descriptionShare;
  dynamic descriptionRental;
  dynamic descriptionFixGroupBooking;

  // Booking Tags
  dynamic descriptionOpenBooking;
  dynamic descriptionNow;
  dynamic descriptionSchedule;
  dynamic descriptionBidding;
  dynamic descriptionMultipleLocation;
  dynamic descriptionFixFare;
  dynamic descriptionCityToCity;
  dynamic descriptionZone;
  dynamic descriptionAirport;
  dynamic descriptionDestinationLater;
  dynamic descriptionSplitPayment;
  dynamic descriptionReturn;
  dynamic descriptionRedZone;
  dynamic descriptionGuestToken;
  dynamic descriptionOutsideBoundary;
  dynamic descriptionWeekly;

  // Errors
  dynamic errorPleaseEnterPhoneNumber;
  dynamic errorPleaseEnterValidPhoneNumber;
  dynamic errorPleaseEnterEmail;
  dynamic errorPleaseEnterValidEmail;
  dynamic errorPleaseEnterPassword;
  dynamic errorPleaseEnterOtp;
  dynamic errorPleaseEnterValidFirstName;
  dynamic errorPleaseEnterValidLastName;
  dynamic errorPasswordAndConfirmPasswordMustBeSame;

  // Profile
  dynamic headingProfile;
  dynamic headingName;
  dynamic headingGender;
  dynamic descriptionMale;
  dynamic descriptionFemale;
  dynamic descriptionNotSet;
  dynamic descriptionProfileName;
  dynamic descriptionProfilePhone;
  dynamic descriptionProfileEmail;
  dynamic buttonUpdate;

  // Image Picker
  dynamic descriptionUploadProfile;
  dynamic descriptionCamera;
  dynamic descriptionImage;
  dynamic descriptionPdf;
  dynamic buttonCancel;

  // Document
  dynamic headingDocument;
  dynamic subHeadingAdd;
  dynamic subHeadingEdit;
  dynamic hintDocumentId;
  dynamic hintUniqueId;
  dynamic hintExpiryDate;
  dynamic descriptionUploadDocument;
  dynamic descriptionIdNo;
  dynamic descriptionExpDate;
  dynamic descriptionPending;
  dynamic descriptionUploaded;
  dynamic descriptionAccepted;
  dynamic descriptionRejected;
  dynamic descriptionDocExpired;
  dynamic descriptionPermissionRequired;
  dynamic buttonSave;
  dynamic buttonDone;
  dynamic errorNoDocumentFound;
  dynamic errorPleaseDocumentId;
  dynamic errorPleaseExpiryDate;
  dynamic errorPleaseSelectImage;
  dynamic errorPleaseUpdateDocument;
  dynamic successDocumentUpdated;
  dynamic errorDocumentUpdateFailed;

  // Date Picker
  dynamic headingSelectDate;

  // Referral
  dynamic headingReferral;
  dynamic headingHaveReferralCode;
  dynamic headingReferralPolicy;
  dynamic hintReferralCode;
  dynamic errorAcceptTerms;
  dynamic successReferralCodeCopied;
  dynamic buttonClose;
  dynamic descriptionInviteYourFriendAndEarnMoney;
  dynamic buttonViewReferralPolicy;
  dynamic descriptionYourReferralCode;
  dynamic descriptionTapToCopy;
  dynamic buttonReferYourFriend;
  dynamic descriptionShareReferralCode;
  dynamic descriptionReferralList;
  dynamic descriptionNoDataFound;

  // No Provider Found
  dynamic headingNoProviderFound;
  dynamic descriptionNoProviderFound;

  // Contact Us / Support / Call
  dynamic buttonCall;
  dynamic buttonCallUser;
  dynamic buttonCallSupport;
  dynamic headingCallUserSupport;
  dynamic descriptionThankYouForChoosing;
  dynamic headingContactUs;
  dynamic headingRaiseNewTicket;
  dynamic headingTicketDetail;
  dynamic headingChatWithAppName;
  dynamic descriptionSupportTicketId;
  dynamic descriptionBookingId;
  dynamic descriptionTicketOpen;
  dynamic descriptionTicketClosed;
  dynamic descriptionTicketReopen;
  dynamic descriptionTicketCancelled;
  dynamic descriptionSelectCategory;
  dynamic hintSubject;
  dynamic hintMessage;
  dynamic buttonSubmit;
  dynamic buttonCloseTicket;
  dynamic buttonReopenTicket;
  dynamic buttonRaiseNewTicket;
  dynamic errorPleaseSelectTicketCategory;
  dynamic errorPleaseEnterSubject;
  dynamic errorPleaseEnterMessage;
  dynamic descriptionNoTicketsFound;

  // Payment
  dynamic errorPleaseEnterWalletAmount;
  dynamic errorPleaseSelectCard;
  dynamic errorPleaseEnterCardName;
  dynamic errorPleaseEnterValidCardNumber;
  dynamic errorPleaseEnterValidExpiryDate;
  dynamic errorPleaseEnterValidCvv;
  dynamic errorPleaseEnterRedeemPoint;
  dynamic errorEnterValidRedeemPoint;
  dynamic headingPayments;
  dynamic headingDeleteCard;
  dynamic headingAddCardDetails;
  dynamic headingAddWalletAmount;
  dynamic headingSendMoney;
  dynamic headingSelectPaymentGateway;
  dynamic descriptionDeleteCardMessage;
  dynamic descriptionCustomer;
  dynamic descriptionDriver;
  dynamic descriptionCard;
  dynamic hintEnterAmount;
  dynamic hintCardHolderName;
  dynamic hintCardNumber;
  dynamic hintCvv;
  dynamic buttonAdd;
  dynamic buttonConfirm;
  dynamic buttonSend;
  dynamic buttonTransferMoney;
  dynamic buttonAddNewCard;
  dynamic subHeadingPaymentMethods;
  dynamic errorUserNotFound;
  dynamic hintEnterTransferAmount;

  // Inbox
  dynamic headingInbox;

  // Account Menu
  dynamic headingHelp;
  dynamic headingWallet;
  dynamic headingBookings;
  dynamic headingActivity;
  dynamic headingFavourites;
  dynamic buttonRemove;
  dynamic buttonFavorite;
  dynamic descriptionDeleteFavourite;
  dynamic buttonYes;

  // Settings
  dynamic headingSetting;
  dynamic headingAppearance;
  dynamic headingSelectLanguage;
  dynamic headingDeleteAccount;
  dynamic headingLogout;
  dynamic descriptionAddHome;
  dynamic descriptionAddWork;
  dynamic descriptionShortcuts;
  dynamic descriptionHome;
  dynamic descriptionWork;
  dynamic descriptionLanguage;
  dynamic descriptionLightMode;
  dynamic descriptionDarkMode;
  dynamic descriptionSystemDefault;
  dynamic descriptionDeleteAccount;
  dynamic descriptionLogout;
  dynamic descriptionDelete;
  dynamic descriptionSelectTheme;
  dynamic descriptionAppVersion;

  // Saved Places
  dynamic headingSavedPlaces;
  dynamic headingEditSavedPlace;
  dynamic headingAddSavedPlace;
  dynamic headingDeleteAddress;
  dynamic descriptionConfirmDeleteAddressMessage;
  dynamic descriptionSavedPlace;
  dynamic descriptionLocationNickname;
  dynamic descriptionAddress;
  dynamic descriptionGettingAddress;
  dynamic descriptionMoveMapToSelect;
  dynamic hintLocationNicknameExample;
  dynamic hintSearchLocation;
  dynamic buttonAddNewPlace;
  dynamic buttonSavePlace;
  dynamic buttonEdit;
  dynamic buttonSetLocationOnMap;

  // Redeem
  dynamic headingRedeem;
  dynamic headingRedeemPoints;
  dynamic buttonRedeem;
  dynamic hintEnterPoints;
  dynamic descriptionAvailablePoints;
  dynamic descriptionEquivalent;
  dynamic descriptionAvailablePointsValue;
  dynamic descriptionBalance;
  dynamic errorNoRedeemHistoryFound;
  dynamic descriptionReferralBonus;
  dynamic descriptionBookingBonus;
  dynamic descriptionReviewBonus;
  dynamic descriptionTipBonus;
  dynamic descriptionDailyBookingAcceptedBonus;
  dynamic descriptionDailyBookingCompletedBonus;
  dynamic descriptionAverageRatingBonus;
  dynamic descriptionRewardPointWithdraw;
  dynamic descriptionRewardPointsValue;
  dynamic descriptionReferralProfitBonus;
  dynamic descriptionAwardProfitBonus;

  // Wallet History
  dynamic headingWalletHistory;
  dynamic errorNoWalletHistoryFound;
  dynamic descriptionTransactionId;
  dynamic descriptionReferrerBonus;
  dynamic descriptionDigitalPayment;
  dynamic descriptionAdmin;
  dynamic descriptionTipPayment;
  dynamic descriptionToFriend;
  dynamic descriptionFromFriend;
  dynamic descriptionPenalty;
  dynamic descriptionRideCancellation;
  dynamic descriptionLowRating;
  dynamic descriptionMissedRides;
  dynamic descriptionBookingPayment;
  dynamic descriptionCancelBookingPayment;
  dynamic descriptionBookingProfit;
  dynamic descriptionIncentive;
  dynamic descriptionBankTransfer;
  dynamic descriptionRefund;
  dynamic descriptionRefundReason;
  dynamic descriptionBookingRemainingAmount;
  dynamic descriptionSubscription;

  // Time
  dynamic descriptionUnitValue;
  dynamic descriptionMinutesUnit;

  // Booking Status
  dynamic descriptionDriverAccepted;
  dynamic descriptionWaitingTime;
  dynamic descriptionFreeWaitingTime;
  dynamic descriptionTotalTime;
  dynamic descriptionTotalDistance;
  dynamic descriptionStopTime;
  dynamic descriptionFreeStopTime;
  dynamic descriptionTrafficTime;
  dynamic bookingStatusInRoute;
  dynamic bookingStatusArrivedAtPickup;
  dynamic bookingStatusStarted;
  dynamic bookingStatusArrivedAtStop;
  dynamic descriptionArrivedAtYourDestination;
  dynamic descriptionDriverTimeEstimate;
  dynamic descriptionPinForRide;

  // Current Ride Screen
  dynamic headingRideDetails;
  dynamic subHeadingRideDetails;
  dynamic buttonSendMessage;
  dynamic headingVehicle;
  dynamic headingSelectedRide;
  dynamic headingSelectedRentalRide;
  dynamic headingSelectedVehicle;
  dynamic headingSelectedPaymentOption;
  dynamic descriptionPickup;
  dynamic descriptionStop;
  dynamic descriptionDistanceUnitKm;
  dynamic descriptionPayment;

  // Invoice
  dynamic headingInvoice;
  dynamic buttonViewReceipt;
  dynamic descriptionYouNeedToPayAboveAmount;
  dynamic buttonSubmitInvoice;
  dynamic buttonPayByCash;
  dynamic buttonPay;
  dynamic buttonPayAgain;
  dynamic buttonCancelBooking;

  // Receipt
  dynamic descriptionNoInvoiceData;
  dynamic descriptionReceiptDisclaimer;
  dynamic descriptionThanksForRiding;
  dynamic descriptionThanksForRidingNoName;
  dynamic descriptionMinimumFareApplied;
  dynamic descriptionSubtotal;
  dynamic descriptionTotal;
  dynamic descriptionFree;

  // Payment Gateways
  dynamic descriptionCash;
  dynamic descriptionWallet;
  dynamic descriptionStripe;
  dynamic descriptionPaystack;
  dynamic descriptionRazorpay;
  dynamic descriptionMercadoPago;
  dynamic descriptionPayu;
  dynamic descriptionPago;
  dynamic descriptionZaincash;
  dynamic descriptionHyperpay;
  dynamic descriptionNestpay;
  dynamic descriptionQicard;
  dynamic descriptionMpesa;

  // Corporate
  dynamic subHeadingCorporate;
  dynamic descriptionWouldYouPayByCorporate;

  // Missing Information
  dynamic subHeadingMissingInformation;
  dynamic headingRequiredActions;
  dynamic descriptionBookWhenResolved;
  dynamic errorPleaseUpdateProfile;
  dynamic errorPleaseUpdateMandatoryDocument;
  dynamic errorPleaseSelectGender;
  dynamic errorNotApprovedYet;
  dynamic errorAdminReviewYourDocument;
  dynamic errorAdminDocRejected;
  dynamic errorAdminDocExpired;
  dynamic descriptionYourAccountIsDeclined;
  dynamic descriptionYourAccountIsBlocked;
  dynamic buttonLogout;
  dynamic buttonContactUs;

  // Bidding
  dynamic descriptionWishToBid;
  dynamic headingBidRequest;
  dynamic descriptionEnterBidAmount;
  dynamic descriptionYourBid;
  dynamic buttonConfirmBid;
  dynamic headingBiddingRequest;
  dynamic descriptionBidAmountFor;
  dynamic buttonAccept;
  dynamic buttonReject;

  // Booking - Buttons
  dynamic buttonApply;
  dynamic buttonRetry;
  dynamic buttonConfirmPickup;
  dynamic buttonConfirmStop;

  // Booking - Headings
  dynamic headingPromoOffers;
  dynamic headingCancellationPolicy;
  dynamic headingChooseRide;
  dynamic headingFareEstimation;
  dynamic headingConfirmDetails;
  dynamic headingConfirmPickupSpot;
  dynamic headingMessageToYourDriver;
  dynamic headingPlanYourRide;
  dynamic headingAddStops;
  dynamic headingAddAStop;
  dynamic headingAddStopOnMap;

  // Booking - Descriptions
  dynamic descriptionDropOff;
  dynamic descriptionDestination;
  dynamic descriptionApplyPromoCode;
  dynamic descriptionPromoApplied;
  dynamic descriptionSetYourPickupSpot;
  dynamic descriptionSetYourDestination;
  dynamic descriptionDragMapToMovePin;
  dynamic descriptionForMe;
  dynamic descriptionSetPickup;
  dynamic descriptionSetDestination;
  dynamic descriptionConfirmPickup;
  dynamic descriptionConfirmDestination;
  dynamic descriptionPickupNow;
  dynamic descriptionLater;

  // Booking - Hints
  dynamic hintSearch;
  dynamic hintEnterStopLocation;
  dynamic hintWriteNotes;

  // Booking - Errors
  dynamic errorUnableToLoadVehicles;
  dynamic errorUnableToLoadPromoCodes;
  dynamic errorUnableToLoadCancellationPolicy;
  dynamic errorNoVehiclesAvailable;
  dynamic errorNoVehiclesDescription;
  dynamic errorNoPromoOffers;
  dynamic errorNoCancellationPolicy;
  dynamic errorNoResultsFound;

  // Address Validation
  dynamic errorPleaseEnterPickupLocation;
  dynamic errorPleaseEnterValidPickupLocation;
  dynamic errorPleaseEnterDropOffAddress;
  dynamic errorPickupDestinationMustBeDifferent;
  dynamic errorPickupStopMustBeDifferent;
  dynamic errorStopDropOffDifferent;
  dynamic errorConsecutiveStopMustBeDifferent;
  dynamic errorSelectAddressFromSameCountry;
  dynamic errorPleaseSelectFutureTime;

  // Cancel Trip
  dynamic headingCancelTrip;
  dynamic headingWhyDoYouWantToCancel;
  dynamic buttonKeepMyTrip;
  dynamic descriptionCancelTrip;
  dynamic subHeadingTripDetails;
  dynamic headingCancelBooking;
  dynamic descriptionAreYouSureYouWantToCancelTheBooking;
  dynamic descriptionCancellationChargeWillBeApplied;
  dynamic hintSelectCancellationReason;
  dynamic hintWriteSpecificReason;
  dynamic descriptionOthers;
  dynamic errorPleaseSelectCancellationReason;
  dynamic errorPleaseEnterValidCancellationReason;

  // Chat
  dynamic descriptionChat;
  dynamic descriptionNoMessagesYet;
  dynamic hintTypeMessage;
  dynamic descriptionToday;
  dynamic descriptionYesterday;

  // Activity
  dynamic headingFilter;
  dynamic headingPast;
  dynamic headingUpcoming;
  dynamic headingHelpAndSafety;
  dynamic hintFrom;
  dynamic hintTo;
  dynamic hintVehicleColor;
  dynamic buttonReceipt;
  dynamic buttonReBook;
  dynamic buttonSetDestinationLater;
  dynamic buttonGetHelp;
  dynamic buttonGoBack;
  dynamic descriptionNoPastBookingsFound;
  dynamic descriptionNoUpcomingTrips;
  dynamic descriptionReserveYourRide;
  dynamic descriptionLastSevenDays;
  dynamic descriptionCurrentMonth;
  dynamic descriptionPreviousMonth;
  dynamic descriptionPreviousSixMonth;
  dynamic descriptionSpecificDates;
  dynamic descriptionDistance;
  dynamic descriptionPlateNo;
  dynamic descriptionDuration;
  dynamic descriptionCancelled;
  dynamic descriptionRated;
  dynamic descriptionNotYetRated;
  dynamic descriptionDriverRating;
  dynamic descriptionSelectReasonForCancellation;
  dynamic descriptionRideWithDriver;
  dynamic descriptionRide;
  dynamic descriptionBookingIdWithSeparator;
  dynamic descriptionReasonPrefix;
  dynamic errorPleaseEnterBothDates;

  // Feedback
  dynamic headingFeedback;
  dynamic subHeadingRateYourRideExperience;
  dynamic subHeadingComment;
  dynamic hintWriteYourRideExperience;
  dynamic subHeadingTipYourDriver;
  dynamic hintEnterTipAmount;
  dynamic errorTipPaymentFailed;
  dynamic descriptionSelectPaymentGateway;
  dynamic buttonMaybeLater;
  dynamic descriptionRateAwful;
  dynamic descriptionRateSad;
  dynamic descriptionRateGood;
  dynamic descriptionRateVeryGood;
  dynamic descriptionRateExcellent;

  // Ride for other
  dynamic headingNewRider;
  dynamic headingChooseARider;
  dynamic headingSwitchRider;
  dynamic descriptionDriversWillSeeName;
  dynamic descriptionNameChangeNote;
  dynamic hintEnterFirstName;
  dynamic hintEnterLastName;
  dynamic hintEnterPhoneNumber;
  dynamic descriptionPhoneNotShared;
  dynamic descriptionAddRiderConsentPrefix;
  dynamic buttonAddRider;
  dynamic descriptionAddRiderConsentSuffix;
  dynamic hintSearchNameOrNumber;
  dynamic descriptionContactsPermissionRequired;
  dynamic buttonOpenSettings;
  dynamic buttonAddManually;
  dynamic descriptionFrequentContacts;
  dynamic descriptionDeviceContacts;
  dynamic descriptionNoContactsFound;
  dynamic descriptionNoMatchingContacts;
  dynamic descriptionMe;
  dynamic buttonAddNewContact;
  dynamic descriptionRideFor;

  // Emergency Contacts
  dynamic headingAddEmergencyContact;
  dynamic headingUpdateEmergencyContact;
  dynamic subHeadingEmergencyContacts;

  // App Update
  dynamic headingWeAreGettingBetter;
  dynamic descriptionAppUpdate;
  dynamic buttonUpdateNow;
  dynamic buttonSkipForNow;

  // Delivery
  dynamic headingDelivery;
  dynamic hintSearchRestaurants;
  dynamic descriptionOffers;
  dynamic headingAllRestaurants;
  dynamic descriptionClosed;
  dynamic errorDeliveryNotAvailable;
  dynamic errorNoRestaurantsInCategory;
  dynamic errorNoRestaurantsFound;

  /// Update strings from API JSON response
  void updateFromJson(Map<String, dynamic> json) {
    // App
    appName = json['app_name'];

    // Buttons
    buttonEmail = json['button_email'];
    buttonNext = json['button_next'];
    buttonContinue = json['button_continue'];
    buttonContinueWithGoogle = json['button_continue_with_google'];
    buttonContinueWithApple = json['button_continue_with_apple'];
    buttonContinueWithEmail = json['button_continue_with_email'];
    buttonResendOtp = json['button_resend_otp'];
    buttonForgotPassword = json['button_forgot_password'];

    // Hints
    hintPhoneNumber = json['hint_phone_number'];
    hintFirstName = json['hint_first_name'];
    hintLastName = json['hint_last_name'];
    hintEmailExample = json['hint_email_example'];
    hintPassword = json['hint_password'];
    hintNumberExample = json['hint_number_example'];
    hintEnterPassword = json['hint_enter_password'];
    hintConfirmPassword = json['hint_confirm_password'];

    // Headings
    headingWhatIsYourName = json['heading_what_is_your_name'];
    headingAcceptTermsAndReviewPrivacyNotice = json['heading_accept_terms_and_review_privacy_notice'];
    headingLegal = json['heading_legal'];
    descriptionTermsConditions = json['description_terms_conditions'];
    descriptionPrivacyPolicy = json['description_privacy_policy'];
    headingWhatIsYourEmailAddress = json['heading_what_is_your_email_address'];
    headingCreatePassword = json['heading_create_password'];
    headingResetPassword = json['heading_reset_password'];
    headingVerifyAccount = json['heading_verify_account'];
    headingEnterYourMobileNumber = json['heading_enter_your_mobile_number'];
    headingConnectingNearbyDrivers = json['heading_connecting_nearby_drivers'];

    // Descriptions
    descriptionLetUsKnowHowToProperlyAddressYou = json['description_let_us_know_how_to_properly_address_you'];
    descriptionYouWillUseThisNumber = json['description_you_will_use_this_number'];
    descriptionVerificationCodeSendToNumber = json['description_verification_code_send_to_number'];
    descriptionYouWillUseThisEmail = json['description_you_will_use_this_email'];
    descriptionIAgree = json['description_i_agree'];
    descriptionAgreeTerms = json['description_agree_terms'];
    descriptionEnterOtpSentTo = json['description_enter_otp_sent_to'];
    descriptionResendPhoneCode = json['description_resend_phone_code'];
    descriptionResendEmailCode = json['description_resend_email_code'];
    descriptionEmail = json['description_email'];
    descriptionPhone = json['description_phone'];
    descriptionPassword = json['description_password'];
    descriptionTermsOfUse = json['description_terms_of_use'];
    descriptionPrivacyNotice = json['description_privacy_notice'];
    descriptionChangedYourMobileNumber = json['description_changed_your_mobile_number'];
    descriptionChangedYourEmailAddress = json['description_changed_your_email_address'];
    descriptionLoginWithOtpInstead = json['description_login_with_otp_instead'];
    descriptionLoginWithPasswordInstead = json['description_login_with_password_instead'];
    descriptionEnterPasswordFor = json['description_enter_password_for'];
    descriptionByContinuingYouAgree = json['description_by_continuing_you_agree'];

    // Ride Types
    descriptionNormal = json['description_normal'];
    descriptionShare = json['description_share'];
    descriptionRental = json['description_rental'];
    descriptionFixGroupBooking = json['description_fix_group_booking'];

    // Booking Tags
    descriptionOpenBooking = json['description_open_booking'];
    descriptionNow = json['description_now'];
    descriptionSchedule = json['description_schedule'];
    descriptionBidding = json['description_bidding'];
    descriptionMultipleLocation = json['description_multiple_location'];
    descriptionFixFare = json['description_fix_fare'];
    descriptionCityToCity = json['description_city_to_city'];
    descriptionZone = json['description_zone'];
    descriptionAirport = json['description_airport'];
    descriptionDestinationLater = json['description_destination_later'];
    descriptionSplitPayment = json['description_split_payment'];
    descriptionReturn = json['description_return'];
    descriptionRedZone = json['description_red_zone'];
    descriptionGuestToken = json['description_guest_token'];
    descriptionOutsideBoundary = json['description_outside_boundary'];
    descriptionWeekly = json['description_weekly'];

    // Errors
    errorPleaseEnterPhoneNumber = json['error_please_enter_phone_number'];
    errorPleaseEnterValidPhoneNumber = json['error_please_enter_valid_phone_number'];
    errorPleaseEnterEmail = json['error_please_enter_email'];
    errorPleaseEnterValidEmail = json['error_please_enter_valid_email'];
    errorPleaseEnterPassword = json['error_please_enter_password'];
    errorPleaseEnterOtp = json['error_please_enter_otp'];
    errorPleaseEnterValidFirstName = json['error_please_enter_valid_first_name'];
    errorPleaseEnterValidLastName = json['error_please_enter_valid_last_name'];
    errorPasswordAndConfirmPasswordMustBeSame = json['error_password_and_confirm_password_must_be_same'];

    // Profile
    headingProfile = json['heading_profile'];
    headingName = json['heading_name'];
    headingGender = json['heading_gender'];
    descriptionMale = json['description_male'];
    descriptionFemale = json['description_female'];
    descriptionNotSet = json['description_not_set'];
    descriptionProfileName = json['description_profile_name'];
    descriptionProfilePhone = json['description_profile_phone'];
    descriptionProfileEmail = json['description_profile_email'];
    buttonUpdate = json['button_update'];

    // Image Picker
    descriptionUploadProfile = json['description_upload_profile'];
    descriptionCamera = json['description_camera'];
    descriptionImage = json['description_image'];
    descriptionPdf = json['description_pdf'];
    buttonCancel = json['button_cancel'];

    // Document
    headingDocument = json['heading_document'];
    subHeadingAdd = json['sub_heading_add'];
    subHeadingEdit = json['sub_heading_edit'];
    hintDocumentId = json['hint_document_id'];
    hintUniqueId = json['hint_unique_id'];
    hintExpiryDate = json['hint_expiry_date'];
    descriptionUploadDocument = json['description_upload_document'];
    descriptionIdNo = json['description_id_no'];
    descriptionExpDate = json['description_exp_date'];
    descriptionPending = json['description_pending'];
    descriptionUploaded = json['description_uploaded'];
    descriptionAccepted = json['description_accepted'];
    descriptionRejected = json['description_rejected'];
    descriptionDocExpired = json['description_doc_expired'];
    descriptionPermissionRequired = json['description_permission_required'];
    buttonSave = json['button_save'];
    buttonDone = json['button_done'];
    errorNoDocumentFound = json['error_no_document_found'];
    errorPleaseDocumentId = json['error_please_document_id'];
    errorPleaseExpiryDate = json['error_please_expiry_date'];
    errorPleaseSelectImage = json['error_please_select_image'];
    errorPleaseUpdateDocument = json['error_please_update_document'];
    successDocumentUpdated = json['success_document_updated'];
    errorDocumentUpdateFailed = json['error_document_update_failed'];

    // Date Picker
    headingSelectDate = json['heading_select_date'];

    // Referral
    headingReferral = json['heading_referral'];
    headingHaveReferralCode = json['heading_have_referral_code'];
    headingReferralPolicy = json['heading_referral_policy'];
    hintReferralCode = json['hint_referral_code'];
    errorAcceptTerms = json['error_accept_terms'];
    successReferralCodeCopied = json['success_referral_code_copied'];
    buttonClose = json['button_close'];
    descriptionInviteYourFriendAndEarnMoney = json['description_invite_your_friend_and_earn_money'];
    buttonViewReferralPolicy = json['button_view_referral_policy'];
    descriptionYourReferralCode = json['description_your_referral_code'];
    descriptionTapToCopy = json['description_tap_to_copy'];
    buttonReferYourFriend = json['button_refer_your_friend'];
    descriptionShareReferralCode = json['description_share_referral_code'];
    descriptionReferralList = json['description_referral_list'];
    descriptionNoDataFound = json['description_no_data_found'];

    // No Provider Found
    headingNoProviderFound = json['heading_no_provider_found'];
    descriptionNoProviderFound = json['description_no_provider_found'];

    // Contact Us / Support / Call
    buttonCall = json['button_call'];
    buttonCallUser = json['button_call_user'];
    buttonCallSupport = json['button_call_support'];
    headingCallUserSupport = json['heading_call_user_support'];
    descriptionThankYouForChoosing = json['description_thank_you_for_choosing'];
    headingContactUs = json['heading_contact_us'];
    headingRaiseNewTicket = json['heading_raise_new_ticket'];
    headingTicketDetail = json['heading_ticket_detail'];
    headingChatWithAppName = json['heading_chat_with_app_name'];
    descriptionSupportTicketId = json['description_support_ticket_id'];
    descriptionBookingId = json['description_booking_id'];
    descriptionTicketOpen = json['description_ticket_open'];
    descriptionTicketClosed = json['description_ticket_closed'];
    descriptionTicketReopen = json['description_ticket_reopen'];
    descriptionTicketCancelled = json['description_ticket_cancelled'];
    descriptionSelectCategory = json['description_select_category'];
    hintSubject = json['hint_subject'];
    hintMessage = json['hint_message'];
    buttonSubmit = json['button_submit'];
    buttonCloseTicket = json['button_close_ticket'];
    buttonReopenTicket = json['button_reopen_ticket'];
    buttonRaiseNewTicket = json['button_raise_new_ticket'];
    errorPleaseSelectTicketCategory = json['error_please_select_ticket_category'];
    errorPleaseEnterSubject = json['error_please_enter_subject'];
    errorPleaseEnterMessage = json['error_please_select_enter_message'];
    descriptionNoTicketsFound = json['description_no_tickets_found'];

    // Payment
    errorPleaseEnterWalletAmount = json['error_please_enter_wallet_amount'];
    errorPleaseSelectCard = json['error_please_select_card'];
    errorPleaseEnterCardName = json['error_please_enter_card_name'];
    errorPleaseEnterValidCardNumber = json['error_please_enter_valid_card_number'];
    errorPleaseEnterValidExpiryDate = json['error_please_enter_valid_expiry_date'];
    errorPleaseEnterValidCvv = json['error_please_enter_valid_cvv'];
    errorPleaseEnterRedeemPoint = json['error_please_enter_redeem_point'];
    errorEnterValidRedeemPoint = json['error_enter_valid_redeem_point'];
    headingPayments = json['heading_payments'];
    headingDeleteCard = json['heading_delete_card'];
    headingAddCardDetails = json['heading_add_card_details'];
    headingAddWalletAmount = json['heading_add_wallet_amount'];
    headingSendMoney = json['heading_send_money'];
    headingSelectPaymentGateway = json['heading_select_payment_gateway'];
    descriptionDeleteCardMessage = json['description_delete_card_message'];
    descriptionCustomer = json['description_customer'];
    descriptionDriver = json['description_driver'];
    descriptionCard = json['description_card'];
    hintEnterAmount = json['hint_enter_amount'];
    hintCardHolderName = json['hint_card_holder_name'];
    hintCardNumber = json['hint_card_number'];
    hintCvv = json['hint_cvv'];
    buttonAdd = json['button_add'];
    buttonConfirm = json['button_confirm'];
    buttonSend = json['button_send'];
    buttonTransferMoney = json['button_transfer_money'];
    buttonAddNewCard = json['button_add_new_card'];
    subHeadingPaymentMethods = json['sub_heading_payment_methods'];
    errorUserNotFound = json['error_user_not_found'];
    hintEnterTransferAmount = json['hint_enter_transfer_amount'];

    // Inbox
    headingInbox = json['heading_inbox'];

    // Account Menu
    headingHelp = json['heading_help'];
    headingWallet = json['heading_wallet'];
    headingBookings = json['heading_bookings'];
    headingActivity = json['heading_activity'];
    headingFavourites = json['heading_favourites'];
    buttonRemove = json['button_remove'];
    buttonFavorite = json['button_favorite'];
    descriptionDeleteFavourite = json['description_delete_favourite'];
    buttonYes = json['button_yes'];

    // Settings
    headingSetting = json['heading_setting'];
    headingAppearance = json['heading_appearance'];
    headingSelectLanguage = json['heading_select_language'];
    headingDeleteAccount = json['heading_delete_account'];
    headingLogout = json['heading_logout'];
    descriptionAddHome = json['description_add_home'];
    descriptionAddWork = json['description_add_work'];
    descriptionShortcuts = json['description_shortcuts'];
    descriptionHome = json['description_home'];
    descriptionWork = json['description_work'];
    descriptionLanguage = json['description_language'];
    descriptionLightMode = json['description_light_mode'];
    descriptionDarkMode = json['description_dark_mode'];
    descriptionSystemDefault = json['description_system_default'];
    descriptionDeleteAccount = json['description_delete_account'];
    descriptionLogout = json['description_logout'];
    descriptionDelete = json['description_delete'];
    descriptionSelectTheme = json['description_select_theme'];
    descriptionAppVersion = json['description_app_version'];

    // Saved Places
    headingSavedPlaces = json['heading_saved_places'];
    headingEditSavedPlace = json['heading_edit_saved_place'];
    headingAddSavedPlace = json['heading_add_saved_place'];
    headingDeleteAddress = json['heading_delete_address'];
    descriptionConfirmDeleteAddressMessage = json['description_confirm_delete_address_message'];
    descriptionSavedPlace = json['description_saved_place'];
    descriptionLocationNickname = json['description_location_nickname'];
    descriptionAddress = json['description_address'];
    descriptionGettingAddress = json['description_getting_address'];
    descriptionMoveMapToSelect = json['description_move_map_to_select'];
    hintLocationNicknameExample = json['hint_location_nickname_example'];
    hintSearchLocation = json['hint_search_location'];
    buttonAddNewPlace = json['button_add_new_place'];
    buttonSavePlace = json['button_save_place'];
    buttonEdit = json['button_edit'];
    buttonSetLocationOnMap = json['button_set_location_on_map'];

    // Redeem
    headingRedeem = json['heading_redeem'];
    headingRedeemPoints = json['heading_redeem_points'];
    buttonRedeem = json['button_redeem'];
    hintEnterPoints = json['hint_enter_points'];
    descriptionAvailablePoints = json['description_available_points'];
    descriptionEquivalent = json['description_equivalent'];
    descriptionAvailablePointsValue = json['description_available_points_value'];
    descriptionBalance = json['description_balance'];
    errorNoRedeemHistoryFound = json['error_no_redeem_history_found'];
    descriptionReferralBonus = json['description_referral_bonus'];
    descriptionBookingBonus = json['description_booking_bonus'];
    descriptionReviewBonus = json['description_review_bonus'];
    descriptionTipBonus = json['description_tip_bonus'];
    descriptionDailyBookingAcceptedBonus = json['description_daily_booking_accepted_bonus'];
    descriptionDailyBookingCompletedBonus = json['description_daily_booking_completed_bonus'];
    descriptionAverageRatingBonus = json['description_average_rating_bonus'];
    descriptionRewardPointWithdraw = json['description_reward_point_withdraw'];
    descriptionRewardPointsValue = json['description_reward_points_value'];
    descriptionReferralProfitBonus = json['description_referral_profit_bonus'];
    descriptionAwardProfitBonus = json['description_description_award_profit_bonus'];

    // Wallet History
    headingWalletHistory = json['heading_wallet_history'];
    errorNoWalletHistoryFound = json['error_no_wallet_history_found'];
    descriptionTransactionId = json['description_transaction_id'];
    descriptionReferrerBonus = json['description_referrer_bonus'];
    descriptionDigitalPayment = json['description_digital_payment'];
    descriptionAdmin = json['description_admin'];
    descriptionTipPayment = json['description_tip_payment'];
    descriptionToFriend = json['description_to_friend'];
    descriptionFromFriend = json['description_from_friend'];
    descriptionPenalty = json['description_penalty'];
    descriptionRideCancellation = json['description_ride_cancellation'];
    descriptionLowRating = json['description_low_rating'];
    descriptionMissedRides = json['description_missed_rides'];
    descriptionBookingPayment = json['description_booking_payment'];
    descriptionCancelBookingPayment = json['description_cancel_booking_payment'];
    descriptionBookingProfit = json['description_booking_profit'];
    descriptionIncentive = json['description_incentive'];
    descriptionBankTransfer = json['description_bank_transfer'];
    descriptionRefund = json['description_refund'];
    descriptionRefundReason = json['description_refund_reason'];
    descriptionBookingRemainingAmount = json['description__booking_remaining_amount'];
    descriptionSubscription = json['description_subscription'];

    // Time
    descriptionUnitValue = json['description_unit_value'];
    descriptionMinutesUnit = json['description_minutes_unit'];

    // Booking Status
    descriptionDriverAccepted = json['description_driver_accepted'];
    descriptionWaitingTime = json['description_waiting_time'];
    descriptionFreeWaitingTime = json['description_free_waiting_time'];
    descriptionTotalTime = json['description_total_time'];
    descriptionTotalDistance = json['description_total_distance'];
    descriptionStopTime = json['description_stop_time'];
    descriptionFreeStopTime = json['description_free_stop_time'];
    descriptionTrafficTime = json['description_traffic_time'];
    bookingStatusInRoute = json['booking_status_in_route'];
    bookingStatusArrivedAtPickup = json['booking_status_arrived_at_pickup'];
    bookingStatusStarted = json['booking_status_started'];
    bookingStatusArrivedAtStop = json['booking_status_arrived_at_stop'];
    descriptionArrivedAtYourDestination = json['description_arrived_at_your_destination'];
    descriptionDriverTimeEstimate = json['description_driver_time_estimate'];
    descriptionPinForRide = json['description_pin_for_ride'];

    // Current Ride Screen
    headingRideDetails = json['heading_ride_details'];
    subHeadingRideDetails = json['sub_heading_ride_details'];
    buttonSendMessage = json['button_send_message'];
    headingVehicle = json['heading_vehicle'];
    headingSelectedRide = json['heading_selected_ride'];
    headingSelectedRentalRide = json['heading_selected_rental_ride'];
    headingSelectedVehicle = json['heading_selected_vehicle'];
    headingSelectedPaymentOption = json['heading_selected_payment_option'];
    descriptionPickup = json['description_pickup'];
    descriptionStop = json['description_stop'];
    descriptionDistanceUnitKm = json['description_distance_unit_km'];
    descriptionPayment = json['description_payment'];

    // Invoice
    headingInvoice = json['heading_invoice'];
    buttonViewReceipt = json['button_view_receipt'];
    descriptionYouNeedToPayAboveAmount = json['description_you_need_to_pay_above_amount'];
    buttonSubmitInvoice = json['button_submit_invoice'];
    buttonPayByCash = json['button_pay_by_cash'];
    buttonPay = json['button_pay'];
    buttonPayAgain = json['button_pay_again'];
    buttonCancelBooking = json['button_cancel_booking'];

    // Receipt
    descriptionNoInvoiceData = json['description_no_invoice_data'];
    descriptionReceiptDisclaimer = json['description_receipt_disclaimer'];
    descriptionThanksForRiding = json['description_thanks_for_riding'];
    descriptionThanksForRidingNoName = json['description_thanks_for_riding_no_name'];
    descriptionMinimumFareApplied = json['description_minimum_fare_applied'];
    descriptionSubtotal = json['description_subtotal'];
    descriptionTotal = json['description_total'];
    descriptionFree = json['description_free'];

    // Payment Gateways
    descriptionCash = json['description_cash'];
    descriptionWallet = json['description_wallet'];
    descriptionStripe = json['description_stripe'];
    descriptionPaystack = json['description_paystack'];
    descriptionRazorpay = json['description_razorpay'];
    descriptionMercadoPago = json['description_mercado_pago'];
    descriptionPayu = json['description_payu'];
    descriptionPago = json['description_pago'];
    descriptionZaincash = json['description_zaincash'];
    descriptionHyperpay = json['description_hyperpay'];
    descriptionNestpay = json['description_nestpay'];
    descriptionQicard = json['description_qicard'];
    descriptionMpesa = json['description_mpesa'];

    // Corporate
    subHeadingCorporate = json['sub_heading_corporate'];
    descriptionWouldYouPayByCorporate = json['description_would_you_pay_by_corporate'];

    // Missing Information
    subHeadingMissingInformation = json['sub_heading_missing_information'];
    headingRequiredActions = json['heading_required_actions'];
    descriptionBookWhenResolved = json['description_book_when_resolved'];
    errorPleaseUpdateProfile = json['error_please_update_profile'];
    errorPleaseUpdateMandatoryDocument = json['error_please_update_mandatory_document'];
    errorPleaseSelectGender = json['error_please_select_gender'];
    errorNotApprovedYet = json['error_not_approved_yet'];
    errorAdminReviewYourDocument = json['error_admin_review_your_document'];
    errorAdminDocRejected = json['error_admin_doc_rejected'];
    errorAdminDocExpired = json['error_admin_doc_expired'];
    descriptionYourAccountIsDeclined = json['description_your_account_is_declined'];
    descriptionYourAccountIsBlocked = json['description_your_account_is_blocked'];
    buttonLogout = json['button_logout'];
    buttonContactUs = json['button_contact_us'];

    // Bidding
    descriptionWishToBid = json['description_wish_to_bid'];
    headingBidRequest = json['heading_bid_request'];
    descriptionEnterBidAmount = json['description_enter_bid_amount'];
    descriptionYourBid = json['description_your_bid'];
    buttonConfirmBid = json['button_confirm_bid'];
    headingBiddingRequest = json['heading_bidding_request'];
    descriptionBidAmountFor = json['description_bid_amount_for'];
    buttonAccept = json['button_accept'];
    buttonReject = json['button_reject'];

    // Booking - Buttons
    buttonApply = json['button_apply'];
    buttonRetry = json['button_retry'];
    buttonConfirmPickup = json['button_confirm_pickup'];
    buttonConfirmStop = json['button_confirm_stop'];

    // Booking - Headings
    headingPromoOffers = json['heading_promo_offers'];
    headingCancellationPolicy = json['heading_cancellation_policy'];
    headingChooseRide = json['heading_choose_ride'];
    headingFareEstimation = json['heading_fare_estimation'];
    headingConfirmDetails = json['heading_confirm_details'];
    headingConfirmPickupSpot = json['heading_confirm_pickup_spot'];
    headingMessageToYourDriver = json['heading_message_to_your_driver'];
    headingPlanYourRide = json['heading_plan_your_ride'];
    headingAddStops = json['heading_add_stops'];
    headingAddAStop = json['heading_add_a_stop'];
    headingAddStopOnMap = json['heading_add_stop_on_map'];

    // Booking - Descriptions
    descriptionDropOff = json['description_drop_off'];
    descriptionDestination = json['description_destination'];
    descriptionApplyPromoCode = json['description_apply_promo_code'];
    descriptionPromoApplied = json['description_promo_applied'];
    descriptionSetYourPickupSpot = json['description_set_your_pickup_spot'];
    descriptionSetYourDestination = json['description_set_your_destination'];
    descriptionDragMapToMovePin = json['description_drag_map_to_move_pin'];
    descriptionForMe = json['description_for_me'];
    descriptionSetPickup = json['description_set_pickup'];
    descriptionSetDestination = json['description_set_destination'];
    descriptionConfirmPickup = json['description_confirm_pickup'];
    descriptionConfirmDestination = json['description_confirm_destination'];
    descriptionPickupNow = json['description_pickup_now'];
    descriptionLater = json['description_later'];

    // Booking - Hints
    hintSearch = json['hint_search'];
    hintEnterStopLocation = json['hint_enter_stop_location'];
    hintWriteNotes = json['hint_write_notes'];

    // Booking - Errors
    errorUnableToLoadVehicles = json['error_unable_to_load_vehicles'];
    errorUnableToLoadPromoCodes = json['error_unable_to_load_promo_codes'];
    errorUnableToLoadCancellationPolicy = json['error_unable_to_load_cancellation_policy'];
    errorNoVehiclesAvailable = json['error_no_vehicles_available'];
    errorNoVehiclesDescription = json['error_no_vehicles_description'];
    errorNoPromoOffers = json['error_no_promo_offers'];
    errorNoCancellationPolicy = json['error_no_cancellation_policy'];
    errorNoResultsFound = json['error_no_results_found'];

    // Address Validation
    errorPleaseEnterPickupLocation = json['error_please_enter_pickup_location'];
    errorPleaseEnterValidPickupLocation = json['error_please_enter_valid_pickup_location'];
    errorPleaseEnterDropOffAddress = json['error_please_enter_drop_off_address'];
    errorPickupDestinationMustBeDifferent = json['error_pickup_destination_must_be_different'];
    errorPickupStopMustBeDifferent = json['error_pickup_stop_must_be_different'];
    errorStopDropOffDifferent = json['error_stop_drop_off_different'];
    errorConsecutiveStopMustBeDifferent = json['error_consecutive_stop_must_be_different'];
    errorSelectAddressFromSameCountry = json['error_select_address_from_same_country'];
    errorPleaseSelectFutureTime = json['error_please_select_future_time'];

    // Cancel Trip
    headingCancelTrip = json['heading_cancel_trip'];
    headingWhyDoYouWantToCancel = json['heading_why_do_you_want_to_cancel'];
    buttonKeepMyTrip = json['button_keep_my_trip'];
    descriptionCancelTrip = json['description_cancel_trip'];
    subHeadingTripDetails = json['sub_heading_trip_details'];
    headingCancelBooking = json['heading_cancel_booking'];
    descriptionAreYouSureYouWantToCancelTheBooking = json['description_are_you_sure_you_want_to_cancel_the_booking'];
    descriptionCancellationChargeWillBeApplied = json['description_cancellation_charge_will_be_applied'];
    hintSelectCancellationReason = json['hint_select_cancellation_reason'];
    hintWriteSpecificReason = json['hint_write_specific_reason'];
    descriptionOthers = json['description_others'];
    errorPleaseSelectCancellationReason = json['error_please_select_cancellation_reason'];
    errorPleaseEnterValidCancellationReason = json['error_please_enter_valid_cancellation_reason'];

    // Chat
    descriptionChat = json['description_chat'];
    descriptionNoMessagesYet = json['description_no_messages_yet'];
    hintTypeMessage = json['hint_type_message'];
    descriptionToday = json['description_today'];
    descriptionYesterday = json['description_yesterday'];

    // Activity
    headingFilter = json['heading_filter'];
    headingPast = json['heading_past'];
    headingUpcoming = json['heading_upcoming'];
    headingHelpAndSafety = json['heading_help_and_safety'];
    hintFrom = json['hint_from'];
    hintTo = json['hint_to'];
    hintVehicleColor = json['hint_vehicle_color'];
    buttonReceipt = json['button_receipt'];
    buttonReBook = json['button_re_book'];
    buttonSetDestinationLater = json['button_set_destination_later'];
    buttonGetHelp = json['button_get_help'];
    buttonGoBack = json['button_go_back'];
    descriptionNoPastBookingsFound = json['description_no_past_bookings_found'];
    descriptionNoUpcomingTrips = json['description_no_upcoming_trips'];
    descriptionReserveYourRide = json['description_reserve_your_ride'];
    descriptionLastSevenDays = json['description_last_seven_days'];
    descriptionCurrentMonth = json['description_current_month'];
    descriptionPreviousMonth = json['description_previous_month'];
    descriptionPreviousSixMonth = json['description_previous_six_month'];
    descriptionSpecificDates = json['description_specific_dates'];
    descriptionDistance = json['description_distance'];
    descriptionPlateNo = json['description_plate_no'];
    descriptionDuration = json['description_duration'];
    descriptionCancelled = json['description_cancelled'];
    descriptionRated = json['description_rated'];
    descriptionNotYetRated = json['description_not_yet_rated'];
    descriptionDriverRating = json['description_driver_rating'];
    descriptionSelectReasonForCancellation = json['description_select_reason_for_cancellation'];
    descriptionRideWithDriver = json['description_ride_with_driver'];
    descriptionRide = json['description_ride'];
    descriptionBookingIdWithSeparator = json['description_booking_id_with_separator'];
    descriptionReasonPrefix = json['description_reason_prefix'];
    errorPleaseEnterBothDates = json['error_please_enter_both_dates'];

    // Feedback
    headingFeedback = json['heading_feedback'];
    subHeadingRateYourRideExperience = json['sub_heading_rate_your_ride_experience'];
    subHeadingComment = json['sub_heading_comment'];
    hintWriteYourRideExperience = json['hint_write_your_ride_experience'];
    subHeadingTipYourDriver = json['sub_heading_tip_your_driver'];
    hintEnterTipAmount = json['hint_enter_tip_amount'];
    errorTipPaymentFailed = json['error_tip_payment_failed'];
    descriptionSelectPaymentGateway = json['description_select_payment_gateway'];
    buttonMaybeLater = json['button_maybe_later'];
    descriptionRateAwful = json['description_rate_awful'];
    descriptionRateSad = json['description_rate_sad'];
    descriptionRateGood = json['description_rate_good'];
    descriptionRateVeryGood = json['description_rate_very_good'];
    descriptionRateExcellent = json['description_rate_excellent'];

    // Ride for other
    headingNewRider = json['heading_new_rider'];
    headingChooseARider = json['heading_choose_a_rider'];
    headingSwitchRider = json['heading_switch_rider'];
    descriptionDriversWillSeeName = json['description_drivers_will_see_name'];
    descriptionNameChangeNote = json['description_name_change_note'];
    hintEnterFirstName = json['hint_enter_first_name'];
    hintEnterLastName = json['hint_enter_last_name'];
    hintEnterPhoneNumber = json['hint_enter_phone_number'];
    descriptionPhoneNotShared = json['description_phone_not_shared'];
    descriptionAddRiderConsentPrefix = json['description_add_rider_consent_prefix'];
    buttonAddRider = json['button_add_rider'];
    descriptionAddRiderConsentSuffix = json['description_add_rider_consent_suffix'];
    hintSearchNameOrNumber = json['hint_search_name_or_number'];
    descriptionContactsPermissionRequired = json['description_contacts_permission_required'];
    buttonOpenSettings = json['button_open_settings'];
    buttonAddManually = json['button_add_manually'];
    descriptionFrequentContacts = json['description_frequent_contacts'];
    descriptionDeviceContacts = json['description_device_contacts'];
    descriptionNoContactsFound = json['description_no_contacts_found'];
    descriptionNoMatchingContacts = json['description_no_matching_contacts'];
    descriptionMe = json['description_me'];
    buttonAddNewContact = json['button_add_new_contact'];
    descriptionRideFor = json['description_ride_for'];

    // Emergency Contacts
    headingAddEmergencyContact = json['heading_add_emergency_contact'];
    headingUpdateEmergencyContact = json['heading_update_emergency_contact'];
    subHeadingEmergencyContacts = json['sub_heading_emergency_contacts'];

    // App Update
    headingWeAreGettingBetter = json['heading_we_are_getting_better'];
    descriptionAppUpdate = json['description_app_update'];
    buttonUpdateNow = json['button_update_now'];
    buttonSkipForNow = json['button_skip_for_now'];

    // Delivery
    headingDelivery = json['heading_delivery'];
    hintSearchRestaurants = json['hint_search_restaurants'];
    descriptionOffers = json['description_offers'];
    headingAllRestaurants = json['heading_all_restaurants'];
    descriptionClosed = json['description_closed'];
    errorDeliveryNotAvailable = json['error_delivery_not_available'];
    errorNoRestaurantsInCategory = json['error_no_restaurants_in_category'];
    errorNoRestaurantsFound = json['error_no_restaurants_found'];
  }
}

/// Get string value based on business type, falls back to local string
String getString(dynamic value, String key) {
  final stringObject = _parseStringObject(value);

  if (stringObject != null) {
    final result = switch (businessTypeForString) {
      BusinessType.taxi =>
        stringObject.taxi?.isNotEmpty == true
            ? stringObject.taxi!
            : stringObject.common ?? '',
      BusinessType.quickDelivery =>
        stringObject.quickCommerce?.isNotEmpty == true
            ? stringObject.quickCommerce!
            : stringObject.common ?? '',
      BusinessType.delivery =>
        stringObject.delivery?.isNotEmpty == true
            ? stringObject.delivery!
            : stringObject.common ?? '',
      BusinessType.service =>
        stringObject.service?.isNotEmpty == true
            ? stringObject.service!
            : stringObject.common ?? '',
      BusinessType.courier =>
        stringObject.courier?.isNotEmpty == true
            ? stringObject.courier!
            : stringObject.common ?? '',
      _ => stringObject.common ?? '',
    };

    if (result.isNotEmpty) return result;
  }

  // If value is a non-null string, return it
  if (value != null && value.toString().isNotEmpty) {
    return value.toString();
  }

  // Fallback to local string
  return LocalStrings.getString(key);
}

/// Parse dynamic value to StringObject
StringObject? _parseStringObject(dynamic value) {
  if (value == null) return null;

  try {
    if (value is Map<String, dynamic>) {
      return StringObject.fromJson(value);
    } else if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return StringObject.fromJson(decoded);
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
