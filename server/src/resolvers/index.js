const {mergeResolvers} = require('@graphql-tools/merge');
const usersResolvers = require('./users');
const postsResolvers = require('./posts');
const {resolvers: resolversScalars} = require('graphql-scalars');

const resolvers = [
    resolversScalars,
    usersResolvers,
    postsResolvers,
];


module.exports = mergeResolvers(resolvers)