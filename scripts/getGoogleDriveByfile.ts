import type { Auth } from "googleapis";
import { google } from "googleapis";
import fs from "fs";
import { downloadFile } from "./googleApi/dirveApi";


// 取ってきたいファイル about
const id = ""
const writePath = "content/sideContent/about.md"

const main = async () => {
  const gcpSaKey = process.env.GCP_SA_KEY;
  if (!gcpSaKey) {
    throw new Error('GCP_SA_KEY environment variable is not set');
  }

  let credentials;
  try {
    credentials = JSON.parse(gcpSaKey);
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

      const res = await downloadFile(auth, id);

      // res.data is already an ArrayBuffer, so we can use it directly
      fs.writeFileSync(writePath, Buffer.from(res.data as ArrayBuffer));

};

main().catch((e) => {
  console.error(e);
});
