/*
  CineVision MongoDB seed data (user-service)
  Run with:
    mongosh "mongodb://rootuser:rootpass@localhost:27017/user?authSource=admin" database/mongodb/seed.js
*/

const dbName = "user";
const database = db.getSiblingDB(dbName);

database.createCollection("claim");
database.createCollection("user");

database.claim.createIndex({ claimName: 1 }, { unique: true, name: "uk_claim_name" });
database.user.createIndex({ email: 1 }, { unique: true, name: "uk_user_email" });

const customerClaim = database.claim.findOneAndUpdate(
  { claimName: "CUSTOMER" },
  { $setOnInsert: { claimName: "CUSTOMER" } },
  { upsert: true, returnDocument: "after" }
);

const adminClaim = database.claim.findOneAndUpdate(
  { claimName: "ADMIN" },
  { $setOnInsert: { claimName: "ADMIN" } },
  { upsert: true, returnDocument: "after" }
);

database.user.updateOne(
  { email: "admin@cinevision.local" },
  {
    $setOnInsert: {
      email: "admin@cinevision.local",
      fullName: "CineVision Admin",
      password: "REPLACE_WITH_BCRYPT_HASH_FROM_USER_SERVICE",
      claim: {
        claimId: adminClaim._id,
        claimName: "ADMIN"
      }
    }
  },
  { upsert: true }
);

database.user.updateOne(
  { email: "demo@cinevision.local" },
  {
    $setOnInsert: {
      email: "demo@cinevision.local",
      fullName: "Demo Customer",
      password: "REPLACE_WITH_BCRYPT_HASH_FROM_USER_SERVICE",
      claim: {
        claimId: customerClaim._id,
        claimName: "CUSTOMER"
      }
    }
  },
  { upsert: true }
);

print("Mongo seed completed for CineVision user-service.");
