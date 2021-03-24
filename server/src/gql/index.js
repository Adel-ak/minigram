const { loadFilesSync } = require('@graphql-tools/load-files');
const { mergeTypeDefs } = require('@graphql-tools/merge');
const { typeDefs: typeDefsScalars } = require('graphql-scalars');

const typesArray = loadFilesSync('./src/gql/*.gql');

const typeDefs = [...typeDefsScalars,...typesArray];

module.exports = mergeTypeDefs(typeDefs);