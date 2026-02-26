<div align="center">
<img src="App/WhatsApp%20Legacy/Images/logo_large.png" width=20% height=20%>
<h1>ZevenApp</h1>

Use **WhatsApp** on your old iOS 7+ device
<p><em>"Zeven" means "seven" in Flemish</em></p>

</div>

## Usage
This section is split in two parts: the app and the companion server

### App
- Get the latest build from the releases section on this repository or compile it yourself from source
- Install it on your iDevice

### Server
ZevenApp requires you to host your own server because of the way it interfaces with WhatsApp. We cannot directly contact the WhatsApp servers from the app, and as such it needs a "middleman". You can either selfhost it at home, or get a cheap server to do it on.<br>
<sub>*No, it is most likely not possible to remove this requirement. Please do not ask about it.*</sub>

#### Guide
- Install Bun
- Go to Server/ and run `bun build server.ts utils.ts chat.ts --compile`. Add build target & any other flags if needed.
- Download FFmpeg from:
  * Windows: https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip
  * macOS: https://evermeet.cx/ffmpeg/
  * Linux: https://johnvansickle.com/ffmpeg/
- Create `bin` folder in the folder that has the newly made executable
- Move the `ffmpeg` binary and its dependencies from the previously downloaded archive into that `bin` folder
- Run `server` and profit.

## Developers
<table style="border-collapse: separate; border-spacing: 0 10px;">
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://avatars.githubusercontent.com/u/75683363" style="width:95px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      murdle
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Ported the application to iOS 7 and fixed up everything that the original developers left broken (aka most of the app)
    </td>
  </tr>
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://avatars.githubusercontent.com/u/107697031" style="width:95px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      calvink19
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Reworking the app & server and doing a terrible job at it, without even testing the vibecoded piece of shit that he committed
    </td>
  </tr>
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://avatars.githubusercontent.com/u/77564176" style="width:95px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Lebao3105
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Server rewrite
    </td>
  </tr>
</table>

## Special thanks to...
- **Gian Luca Russo**: the original developer of this project
- **saturngod**: for the `tcpSocketChat` library
- **Dustin Voss** & **Deusty Designs**: for the `AsyncSocket` library
- **Matej Bukovinski**: for the `MBProgressHUD` library
- **Sam Soffes**, **Hexed Bits**, & **Jesse Squires**: for the `SSMessagesViewController` library
- **Skal**: for the `WebP` framework

## Disclaimers
This project is **not affiliated** with “WA for Legacy iOS” by Alwin Lubbers, “Meta Platforms Inc.”, or “WhatsApp Inc.”

This is an **unofficial client** for WhatsApp and is **not affiliated with**, **endorsed by**, or **supported** by WhatsApp Inc. in any way.
By using this application, you acknowledge and agree that:
- **You** are **solely responsible** for the **use** of **your WhatsApp account** with this app.
- **I** (murdle) assume **no responsibility** for **any actions** taken by _WhatsApp Inc._ against your account, including (but not limited to) suspension, banning, or data loss.

**Use at your own risk!**
If you do not agree with these terms, **do not use this application.** A pop-up is also presented in the iOS application.
