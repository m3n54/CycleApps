import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    versionCode: 2,
    versionName: '1.0.1',
    releaseNotes: 'Pembaruan aplikasi Siklus dengan fitur Ruang Pasangan & Timeline Cinta.',
    downloadUrl: '',
    forceUpdate: false,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--versionCode':
        options.versionCode = parseInt(args[++i], 10);
        break;
      case '--versionName':
        options.versionName = args[++i];
        break;
      case '--downloadUrl':
        options.downloadUrl = args[++i];
        break;
      case '--notes':
      case '--releaseNotes':
        options.releaseNotes = args[++i];
        break;
      case '--force':
        options.forceUpdate = true;
        break;
      case '--help':
      case '-h':
        console.log(`
Penggunaan:
  node scripts/update_version_config.mjs [options]

Opsi:
  --versionCode <int>       Nomor versi build Android (cth: 3)
  --versionName <string>    Label versi aplikasi (cth: 1.0.2)
  --downloadUrl <url>       URL link langsung ke file .apk
  --notes <string>          Catatan rilis pembaruan
  --force                   Paksa pengguna untuk update
        `);
        process.exit(0);
    }
  }

  return options;
}

async function main() {
  const options = parseArgs();
  const configPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
  const configData = JSON.parse(readFileSync(configPath, 'utf8'));

  let accessToken = configData.tokens?.access_token;
  const refreshToken = configData.tokens?.refresh_token;

  if (refreshToken) {
    try {
      const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'refresh_token',
          client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho85t8e.apps.googleusercontent.com',
          refresh_token: refreshToken,
        }),
      });
      const data = await res.json();
      if (data.access_token) {
        accessToken = data.access_token;
      }
    } catch (_) {
      // Menggunakan cached token jika refresh offline
    }
  }

  const payload = {
    fields: {
      versionCode: { integerValue: String(options.versionCode) },
      versionName: { stringValue: options.versionName },
      releaseNotes: { stringValue: options.releaseNotes },
      downloadUrl: { stringValue: options.downloadUrl },
      forceUpdate: { booleanValue: options.forceUpdate },
    },
  };

  const url =
    'https://firestore.googleapis.com/v1/projects/cycleapps-nata/databases/(default)/documents/app_config/version';
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errText = await response.text();
    console.error(`Gagal memperbarui Firestore (${response.status}): ${errText}`);
    process.exit(1);
  }

  const result = await response.json();
  console.log('✅ Dokumen app_config/version berhasil diperbarui di Firestore:');
  console.log(JSON.stringify(result.fields, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
