const mutation = require("./mutation");
const query = require("./query");
const { composeResolvers } = require('@graphql-tools/resolvers-composition');
const {isLoggedIn, hasRole, catchAsync} = require('../../utils');
const roles = require('../../constants/authRoles');

const {user} = roles;

const resolversComposition = {
  'Mutation.otpVerifyEmail': [isLoggedIn(),hasRole([user])],
};



const resolvers = {
  Mutation: {...mutation},
  Query: {...query},
  User: {
   
  }
}

module.exports = composeResolvers(resolvers,resolversComposition);
