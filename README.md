# kaching

:: Summary 2024

Project Status - Archived September 2024. Awaiting customer feedback.

Version: Initial Pilot & Testing Implementation
- Onsite Testing still required / awaiting feedback
- Refactoring still required post initial testing and feedback which includes:
  - Styling and layout + moving this into a styles section
  - Refactoring complete order, break implementation into smaller functional widgets (pending feedback and clarification of features required in the first version)
  - Refactoring the payment request, intent call and result await (pending feedback and clarification of features required in the first version)
  - Moving API keys, URL's and other sensitive information into a configuration file/secure keystore.  This may be server based, TBD with client
  - Once testing and any additional services have been finalized, update the String builder in the web_service to include the additional services

::Minor release July 29th 2024
- Update to post in R as per Pieters email
- Query regarding receipt header configuration settings (no current access to backend so this needs to be confirmed by Callpay/Pieter etc)

::Minor release July 25th 2024
- Debug/Release mode update to fix fully formed URL for the payment request (Pieter)

::Minor release July 23rd 2024
- Order number query / cannot re-used order numbers (Still an issue - reverted back to original question about this)

