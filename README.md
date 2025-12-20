<div align="center">
<img src="Xcode%20Project/WhatsApp%20Legacy/Images/logo_large.png" width=20% height=20%>
<h1>WhatsAppX</h1>

use whatsapp on your old iPhone i guess

This project is currently in beta. Please report bugs or ask for help in bag-xml’s Discord server -> `#whatsapp`. *(When reporting bugs or asking for help, please give **as much detail as you can.**)*

</div>

## Compilation

- Install Bun
- Go to Server/ and run `bun build server.ts utils.ts chat.ts --compile`. Add build target & any other flags if needed.
- Download FFmpeg from:
  * Windows: https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip
  * macOS: https://evermeet.cx/ffmpeg/
  * Linux: https://johnvansickle.com/ffmpeg/
- Create `ffmpeg` folder in the folder that has the newly made executable
- Move the previously downloaded `ffmpeg` and its dependencies into that `ffmpeg` folder
- Run `server` and profit.

(The Windows Phone version of the server is [here](https://github.com/lebao3105/WhatsAppX). The iOS version will use the server in this repository.)

## Developers
<table style="border-collapse: separate; border-spacing: 0 10px;">
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://avatars.githubusercontent.com/u/107697031" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      calvink19
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Reworking the iOS client & server
    </td>
  </tr>
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://avatars.githubusercontent.com/u/77564176" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Lebao3105
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Server rewrite & contributed to the Windows Phone 8.1 client
    </td>
  </tr>
 <tr>
    <td style="vertical-align: middle;">
      <img src="https://cdn.discordapp.com/avatars/274765047342039040/71631003d16f8893dc72f789c1c992d6.png" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      zemonkamin
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Contributed to Windows Phone 8.1 client & server upgrades
    </td>
  </tr>

</table>

## Special thanks to...
- **Gian Luca Russo**: the original developer of this project
- **saturngod**: for the `tcpSocketChat` library
- **John Engelhart**: for the `JSONKit` library
- **Dustin Voss** & **Deusty Designs**: for the `AsyncSocket` library
- **Matej Bukovinski**: for the `MBProgressHUD` library
- **Sam Soffes**, **Hexed Bits**, & **Jesse Squires**: for the `SSMessagesViewController` library
- **Skal**: for the `WebP` framework

## Disclaimers
This project is **not affiliated** with “WA for Legacy iOS” by Alwin Lubbers, “Meta Platforms Inc.”, or “WhatsApp Inc.”

This is an **unofficial client** for WhatsApp and is **not affiliated with**, **endorsed by**, or **supported** by WhatsApp Inc. in any way.
By using this application, you acknowledge and agree that:
- **You** are **solely responsible** for the **use** of **your WhatsApp account** with this app.
- **I** (calvink19) assume **no responsibility** for **any actions** taken by _WhatsApp Inc._ against your account, including (but not limited to) suspension, banning, or data loss.

**Use at your own risk!**
If you do not agree with these terms, **do not use this application.** A pop-up is also presented in the iOS application.
