const { ApolloError, ForbiddenError } = require("apollo-server");
const shortid = require('shortid');
const { createWriteStream, existsSync, mkdirSync, unlink } = require('fs');
const admin = require('firebase-admin');
const sdkKey = require('./credentials/firebase-sdk-private-key.json');
const IS_DEV = process.env.NODE_ENV === "development";

const credential = admin.credential.cert(sdkKey);

const fbApp = admin.initializeApp({
  credential,
  storageBucket: 'tbdl-f777a.appspot.com',
});



const catchAsync = (asyncFunction) => {
  return async (...args) => {
    try {
      return await asyncFunction(...args);
    } catch (error) {

      if (IS_DEV) {
        console.log("🚀 ~ catchAsync error", error);
      }

      if (error instanceof ApolloError || error instanceof ForbiddenError) {
        throw error;
      } else {
        throw new ApolloError("Oops!", 500, {
          title: "Something went wrong.",
          error: error.message,
          stack: error.stack,
        });
      }
    }
  };
};

const isLoggedIn = () => (next) => catchAsync(async (root, args, context, info) => {
  const { authorization } = context.req.headers;
  if (authorization.includes('Bearer')) {
    const token = authorization.split('Bearer ')[1];
    const decodedIdToken = await fbApp.auth().verifyIdToken(token);
    if (decodedIdToken) {
      return next(root, args, { ...context, user: decodedIdToken }, info);
    }
  }




  throw new ForbiddenError("Not Authorized");
});

const hasRole = (roles) => (next) => catchAsync(async (root, args, context, info) => {
  let currentUserRole = context.user.role;
  const containesRole = roles.includes(currentUserRole);
  if (!containesRole) {
    throw new ApolloError(`You are not authorized!`);
  }

  return next(root, args, context, info);
});

module.exports = {
  catchAsync,
  isLoggedIn,
  hasRole,
  admin: fbApp
}