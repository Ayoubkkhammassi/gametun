-- AlterTable
ALTER TABLE "profiles" ADD COLUMN     "favoriteGenres" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "funFacts" JSONB,
ADD COLUMN     "hasMic" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "photoUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "platform" TEXT,
ADD COLUMN     "playerType" TEXT,
ADD COLUMN     "rank" TEXT,
ADD COLUMN     "spokenLanguages" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "yearsExperience" INTEGER;
