require("dotenv").config();
const { createServer } = require("http");
const express = require("express");
const { ApolloServer, PubSub, ApolloError, GraphQLUpload } = require("apollo-server-express");
const { applyMiddleware } = require("graphql-middleware");
const { makeExecutableSchema } = require("@graphql-tools/schema");
const morgan = require("morgan");
const cors = require("cors");
const path = require("path");
const typeDefs = require("./gql");
const resolvers = require("./resolvers");
const {userLoader} = require("./dataLoader/auth");

const isDev = process.env.NODE_ENV === "development";
const PORT = process.env.PORT || 5000;
const app = express();

const whitelist = [
  "http://localhost:5000",
  "http://192.168.1.15:5000",
  "http://192.168.0.28:5000",
  "electron://altair",
];

const corsOptions = {
  origin: function (origin, callback) {
    if (whitelist.indexOf(origin) !== -1 || !origin) {
      callback(null, true);
    } else {
      callback(new ApolloError("Not allowed by CORS"));
    }
  },
  methods: ["POST"],
};

app.use(cors(corsOptions));
app.use(morgan("dev"));
app.use("/assets", express.static(path.join(__dirname, "..", "assets")));
app.use("/token", express.static(path.join(__dirname, "..", "assets/token")));

const schema = makeExecutableSchema({
  typeDefs,
  resolvers: {
    ...resolvers,
    Upload: GraphQLUpload,
  },
});

const pubSub = new PubSub();


 const server = new ApolloServer({
  context: async (context) => {
    
    return { ...context, pubSub, userLoader };
  },
  tracing: true,
  schema: applyMiddleware(schema),
  introspection: isDev,
  playground: true,
  
  // !isDev ? {

  //   subscriptionEndpoint: "ws://localhost:5000/graphql",
  // }:true
});

server.applyMiddleware({
  app,
  path: "/graphql",
  onHealthCheck: async (req) =>{
    const healthCheck = await new Promise((resolve, reject) => {
        resolve(true);
    });

    return healthCheck;
  }
   
});

const httpServer = createServer(app);

server.installSubscriptionHandlers(httpServer);

httpServer.listen(PORT, () => {
  console.log(`
      Server ready at http://localhost:${PORT}${server.graphqlPath}
      \n
      Subscriptions ready at ws://localhost:${PORT}${server.subscriptionsPath}
  `);
});
