import {
  Controller,
  Get,
  NotFoundException,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { AppConfig } from '../../config/configuration';
import { Public } from '../../common/decorators/public.decorator';

/** Chemin de l'APK servi pour la mise à jour intégrée. */
const APK_PATH = join(process.cwd(), 'public', 'gametun.apk');
/** Métadonnées de version versionnées dans le repo (déployées à chaque push). */
const VERSION_FILE = join(process.cwd(), 'public', 'app-version.json');

/**
 * Système de mise à jour intégré :
 *  - /app/version : dernière version publiée (l'app compare et propose la MAJ).
 *  - /app/download : télécharge le dernier APK.
 */
@Controller('app')
export class AppUpdateController {
  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  @Public()
  @Get('version')
  version() {
    // Priorité au fichier versionné (mis à jour automatiquement à chaque push),
    // avec repli sur les variables d'environnement.
    let versionCode = this.config.get('appVersionCode', { infer: true });
    let versionName = this.config.get('appVersionName', { infer: true });
    let message = this.config.get('appUpdateMessage', { infer: true });
    let mandatory = false;
    if (existsSync(VERSION_FILE)) {
      try {
        const f = JSON.parse(readFileSync(VERSION_FILE, 'utf-8')) as {
          versionCode?: number;
          versionName?: string;
          message?: string;
          mandatory?: boolean;
        };
        if (typeof f.versionCode === 'number') versionCode = f.versionCode;
        if (f.versionName) versionName = f.versionName;
        if (f.message) message = f.message;
        if (typeof f.mandatory === 'boolean') mandatory = f.mandatory;
      } catch {
        // JSON invalide : on garde les valeurs d'environnement.
      }
    }
    return {
      versionCode,
      versionName,
      message,
      // URL absolue de téléchargement (servie par ce même serveur).
      url: `${this.config.get('publicBaseUrl', { infer: true })}/api/v1/app/download`,
      mandatory,
    };
  }

  @Public()
  @Get('download')
  download(@Res() res: Response) {
    if (!existsSync(APK_PATH)) {
      throw new NotFoundException('APK indisponible');
    }
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="gametun.apk"',
    );
    res.sendFile(APK_PATH);
  }
}
