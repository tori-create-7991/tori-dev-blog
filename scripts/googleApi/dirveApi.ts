import type { Auth } from "googleapis";
import { google } from "googleapis";

export const copyFile = async (
  auth: Auth.JWT,
  fileId: string,
  toCopyFolder: string,
  name: string
) => {
  const drive = await google.drive({ version: "v3" });
  const date = new Date();

  // const sourceFile = await drive.files.get({
  //   auth,
  //   fileId: Config.spreadsheetIdList.testSpreadsheetId
  // })
  // console.log(sourceFile)

  const copyFile = await drive.files.copy({
    auth,
    fileId: fileId,
    requestBody: {
      parents: [toCopyFolder],
      name: `${name} ${date.getFullYear()}${
        date.getMonth() + 1
      }${date.getDate()}${date.getHours()}${date.getMinutes()}`,
    },
  });

  console.log(copyFile.status);
  console.log(copyFile.statusText);

  return copyFile;
};

/**
 * Downloads a file
 * @param{string} realFileId file ID
 * @param {Auth.JWT}
 * @return{obj} file status
 * */
export const downloadFile = async (auth: Auth.JWT, fileId: string) => {
  const drive = google.drive({ version: "v3", auth });

  const file = await drive.files.get(
    {
      fileId: fileId,
      alt: "media",
    },
    {
      responseType: "arraybuffer",
    }
  );
  console.log(file.status);
  return file;
};

/** */
export const listFiles = async function (auth: Auth.JWT, folderId: string) {
  const drive = google.drive({ version: "v3", auth });
  const params = {
    q: `'${folderId}' in parents and trashed = false`,
  };
  console.log(folderId);

  try {
    // const res = await drive.files.list({
    //   driveId: folderId,
    //   corpora: "drive",
    //   includeItemsFromAllDrives: true,
    //   supportsAllDrives: true,
    // });
    const res = await drive.files.list(params);
    const files = res.data.files;
    if (files) {
      console.log("Files:");
      files.map((file) => {
        // console.log(`${file.name} (${file.id})`);
        console.log(file);
      });

      return files;
    } else {
      console.log("No files found.");
    }
  } catch (err) {
    console.log("The API returned an error: " + err);
  }
};
