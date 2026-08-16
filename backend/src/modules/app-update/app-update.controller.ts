import {
  Controller,
  Get,
  NotFoundException,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import { existsSync } from 'fs';
import { join } from 'path';
import { AppConfig } from '../../config/configuration';
import { Public } from '../../common/decorators/public.decorator';

/** Chemin de l'APK servi pour la mise à jour intégrée. */
const APK_PATH = join(process.cwd(), 'public', 'gametun.apk');

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
    return {
      versionCode: this.config.get('appVersionCode', { infer: true }),
      versionName: this.config.get('appVersionName', { infer: true }),
      message: this.config.get('appUpdateMessage', { infer: true }),
      // URL absolue de téléchargement (servie par ce même serveur).
      url: `${this.config.get('publicBaseUrl', { infer: true })}/api/v1/app/download`,
      mandatory: false,
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
