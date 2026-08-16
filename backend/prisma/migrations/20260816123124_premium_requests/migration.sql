-- CreateEnum
CREATE TYPE "PremiumRequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateTable
CREATE TABLE "premium_requests" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "method" TEXT NOT NULL DEFAULT 'D17',
    "reference" TEXT NOT NULL,
    "status" "PremiumRequestStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "premium_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "premium_requests_status_idx" ON "premium_requests"("status");

-- AddForeignKey
ALTER TABLE "premium_requests" ADD CONSTRAINT "premium_requests_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
