const appDb = process.env.MONGO_APP_DB || "user";
const appUser = process.env.MONGO_APP_USER || "cinevision_user_app";
const appPassword = process.env.MONGO_APP_PASSWORD || "user_app_password_change_me";

const dbRef = db.getSiblingDB(appDb);

const existingUser = dbRef.getUser(appUser);
if (!existingUser) {
  dbRef.createUser({
    user: appUser,
    pwd: appPassword,
    roles: [{ role: "readWrite", db: appDb }]
  });
} else {
  dbRef.updateUser(appUser, {
    pwd: appPassword,
    roles: [{ role: "readWrite", db: appDb }]
  });
}

print(`Application user '${appUser}' is configured on database '${appDb}'.`);
