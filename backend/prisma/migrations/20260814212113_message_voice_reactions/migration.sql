-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('TEXT', 'VOICE');

-- AlterTable
ALTER TABLE "messages" ADD COLUMN     "mediaData" TEXT,
ADD COLUMN     "mediaDuration" INTEGER,
ADD COLUMN     "type" "MessageType" NOT NULL DEFAULT 'TEXT';
