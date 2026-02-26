import axios from "axios";
import crypto from "crypto";
import express from "express";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { Client, MessageMedia } from "whatsapp-web.js";
import { chatCache, refreshChats } from "./cache"
import { withTimeout } from "./utils";

export function setUpListGetters(app: express.Express, client: Client) {
  app.get("/getChats", async (_, res) => {
    if (chatCache.loading) {
      refreshChats(client);
    } else {
      await refreshChats(client);
    }
    res.json({
      chatList: chatCache.chatList,
      groupList: chatCache.groupList,
      loading: chatCache.loading
    });
  });

  app.post("/syncChat/:contactId", async (req, res) => {
    try {
      (await client.getChatById(req.params.contactId)).syncHistory();
      res.status(200);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });

  app.get("/getBroadcasts", async (_, res) => {
    try {
      const broadcasts = await client.getBroadcasts();
      const filteredBroadcasts = broadcasts.filter(
        (broadcast) => broadcast.msgs.length > 0,
      );
      res.json(filteredBroadcasts);
    } catch (error) {
      res.status(500).send("Failed to get broadcasts: " + error.message);
    }
  });

  app.get("/getContacts", async (_, res) => {
    try {
      const allContacts = await client.getContacts();
      const contactList = allContacts.sort((a, b) => {
        const nameA = (a.name || "").toLowerCase();
        const nameB = (b.name || "").toLowerCase();
        if (nameA < nameB) return -1;
        if (nameA > nameB) return 1;
        return 0;
      });
      res.json({ contactList });
    } catch (error) {
      res.status(500).send("Failed to get contacts: " + error.message);
    }
  });

  app.get("/getChatMessages/:contactId", async (req, res) => {
    try {
      const chat = await client.getChatById(req.params.contactId);
      const messages = await chat.fetchMessages({
        limit: parseInt((req.query.limit as string) ?? "100"),
      });

      const filteredMessages = messages.filter(
        (message) => message.type !== "notification_template",
      );

      res.json(filteredMessages);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });
}

export function setUpChatGetters(app: express.Express, client: Client) {
  app.get("/getAvatarImg/:id", async (req, res) => {
    try {
      const profilePicUrl = await withTimeout(
        client.getProfilePicUrl(req.params.id),
        5000
      );
      
      if (!profilePicUrl) {
        return res.status(404).send("");
      }
      
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
      const buffer = Buffer.from(response.data, "binary");

      res.set("Content-Type", response.headers["content-type"]);
      res.send(buffer);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });

  app.get("/getGroupImgHash/:id", async (req, res) => {
    try {
      const profilePicUrl = await client.getProfilePicUrl(
        req.params.id + "@g.us",
      );
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
      const buffer = Buffer.from(response.data, "binary");
      const hash = crypto.createHash("md5").update(buffer).digest("hex");
      res.send(hash);
    } catch (error) {
      res.send(null);
    }
  });

  app.get("/getGroupInfo/:id", async (req, res) => {
    try {
      const chat = await client.getChatById(req.params.id + "@g.us");
      res.json(chat);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });
}

export function setUpChatSetters(app: express.Express, client: Client) {
  app.post("/profileSetName/:name", async (req, res) => {
    const resp = await client.setDisplayName(req.params.name);
    res.status(resp ? 200 : 500);
  });

  app.post("/profileSetStatus/:status", async (req, res) => {
    await client.setStatus(req.params.status);
    res.status(200);
  });

  app.post("/profileSetPicture/:mediaBase64", async (req, res) => {
    const imagePath = path.join(os.tmpdir(), `temp_img_${Date.now()}.jpg`);
    fs.writeFileSync(imagePath, Buffer.from(req.params.mediaBase64, "base64"));
    fs.unlinkSync(imagePath);

    const resp = await client.setProfilePicture(
      MessageMedia.fromFilePath(imagePath),
    );
    res.status(resp ? 200 : 500);
  });

  app.post("/Mute/:id", async (req, res) => {
    let resp: { isMuted: boolean; muteExpiration: number };

    if (req.query.mute === "1") {
      if (req.query.expirationDate as string) {
        resp = await client.muteChat(
          req.params.id,
          new Date(req.query.expirationDate as string),
        );
        res.status(resp.isMuted ? 200 : 500);
      } else {
        resp = await client.muteChat(req.params.id);
        res.status(resp.isMuted ? 200 : 500).send(resp.muteExpiration);
      }
    } else {
      resp = await client.unmuteChat(req.params.id);
      res.status(!resp.isMuted ? 200 : 500);
    }
  });

  app.post("/ArchiveChat/:id", async (req, res) => {
    if (req.query.archive === "1") {
      const resp = await client.archiveChat(req.params.id);
      res.status(resp ? 200 : 500);
    } else {
      const resp = await client.unarchiveChat(req.params.id);
      res.status(!resp ? 200 : 500);
    }
  });

  app.post("/DeleteChat/:id", async (req, res) => {
    const resp = await (await client.getChatById(req.params.id)).delete();
    res.status(resp ? 200 : 500);
  });

  app.post("/profileDeleteAvatar", async (req, res) => {
    const resp = await client.deleteProfilePicture();
    res.status(resp ? 200 : 500);
  });
}
