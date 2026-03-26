# angeles-intel

Angeles Intel. (short for intelligence) is a new mobile app featuring a live incident feed from Angeles National Forest (ANF) dispatch, updated every 60 seconds. Stream Forest Net radio communications live, view incidents on a map, check nearby weather stations, and track aircraft with ADS-B - all without ads or a subscription. Agency personnel can verify with a .gov email for Admin Net access and the ability to manually refresh the incidents feed

> [!NOTE]
>
> This app is currently in open beta, and iOS only. We hope Apple will approve version 1.0 (build 8) soon. Meanwhile, you can access it via TestFlight here: https://testflight.apple.com/join/K69Bmny6



---

### **Roadmap (Upcoming Features)**

**Major Feature: "The Feed"**

- *Description*: A continuously-updated visual feed of chronologically-ordered audio recordings and their speech-to-text counterparts, extracted from Forest Net and Admin Net
- *Purpose*: To help with situational awareness, especially for someone who has missed the radio 'roll out' call covering resources, communcation/radio plan, etc.
- *Tech Effort*: We are already capturing and uploading these recordings to AWS, so this is a natural next step and easy value-add



**Major Feature: Correlation Between Recordings/Transcripts, and CAD Incidents**

- *Description*: Use AI/LLM to extrapolate details and correlate radio recording and transcription pairs with incidents shown in the app
- *Purpose*: Concentration/organization of information easy to digest with minimal tapping
- Tech Effort: Research and host a local LLM (Large Language Model aka "AI"). May need to upgrade Windows scanning machine



**Major Feature: Bulletin Board (Authenticated Users Only)**

- *Description*: Give authenticated users the ability to add and view notes to individual incidents and post broadcast messages on a central feed. The central feed will show both messages posted directly to it, and mention comments added to an incident. This phase of the feature would NOT be visible to non-authenticated users - we'll see see how it goes and consider creating a separate, siloed version for civilians
- *Purpose*: To encourage communication whether it be practical, entertaining, or both between responding or interested parties
- *Tech Effort*: Medium. As we're posturing this as a bulletin board rather than a live chat, expectations of immediacy should be low. Therefore we should be able to put the data into affordable AWS storage, perhaps even scribble into S3 objects