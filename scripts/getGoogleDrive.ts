import type { Auth } from "googleapis";
import { google } from "googleapis";
import fs from "fs";
import { downloadFile, listFiles } from "./googleApi/dirveApi";
import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

const dirivePath = [
  { // mdファイル
    folderId: process.env.GDRIVE_MD_FOLDER_ID,
    wirtePath: "content/posts/",
  },
  { //imagesファイル
    folderId: process.env.GDRIVE_IMAGES_FOLDER_ID,
    wirtePath: "public/images",
  },
];

const main = async () => {
  const gcpSaKey = process.env.GCP_SA_KEY;
  if (!gcpSaKey) {
    throw new Error('GCP_SA_KEY environment variable is not set');
  }

  // Check if folder IDs are set
  if (!process.env.GDRIVE_MD_FOLDER_ID || !process.env.GDRIVE_IMAGES_FOLDER_ID) {
    throw new Error('Google Drive folder IDs are not set in environment variables');
  }

  let credentials;
  try {
    // 環境変数から取得したJSON文字列を処理
    const gcpSaKeyStr = gcpSaKey.replace(/\\"/g, '"');
    credentials = JSON.parse(gcpSaKeyStr);
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw new Error('Failed to parse GCP_SA_KEY: ' + errorMessage);
  }

  const auth = (await google.auth.getClient({
    scopes: [
      "https://www.googleapis.com/auth/drive",
      "https://www.googleapis.com/auth/drive.file",
      "https://www.googleapis.com/auth/drive.appdata",
      "https://www.googleapis.com/auth/drive.file",
      "https://www.googleapis.com/auth/drive.metadata",
      "https://www.googleapis.com/auth/drive.metadata.readonly",
      "https://www.googleapis.com/auth/drive.photos.readonly",
      "https://www.googleapis.com/auth/drive.readonly",
    ],
    credentials,
  })) as Auth.JWT;

  for (const { folderId, wirtePath } of dirivePath) {
    if (!folderId) continue; // Skip if folderId is not set
    const filelist = await listFiles(auth, folderId);
    if (!filelist) continue;

    for (const file of filelist) {
      if (!file.id || !file.name) continue;
      const res = await downloadFile(auth, file.id);
      if (!res.data) continue;

      fs.writeFileSync(`${wirtePath}/${file.name}`, Buffer.from(res.data as ArrayBuffer));
    }
  }
};

main().catch((e) => {
  console.error(e);
});
