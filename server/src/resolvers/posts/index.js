const mutation = require("./mutation");
const query = require("./query");
const { composeResolvers } = require('@graphql-tools/resolvers-composition');
const {isLoggedIn, hasRole, catchAsync, admin} = require('../../utils');
const roles = require('../../constants/authRoles');

const {user} = roles;

const resolversComposition = {
  "Mutation.createPost": [isLoggedIn()],
  "Mutation.deletePost": [isLoggedIn()],
  "Query.getUserPosts": [isLoggedIn()]
};



const resolvers = {
  Mutation: {...mutation},
  Query: {...query},
  Post: {
    user: async (root, args, {userLoader}) => {      
      return await userLoader.load({uid:root.uid});
    }
  },
  UserPosts : {
    user: async (_, __, ___, {variableValues: args}) => {
      if(!args.uid){
        return null
      }
      
      const {photoURL, ...restUser} = await admin.auth().getUser(args.uid);
      return {
        ...restUser,
        avatar: photoURL
      };
    }
  }
}

module.exports = composeResolvers(resolvers,resolversComposition);
