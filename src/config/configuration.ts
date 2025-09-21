export default () => ({
  app: {
    port: parseInt(process.env.PORT ?? '3000', 10),
    nodeEnv: process.env.NODE_ENV ?? 'development',
  },
  mongo: {
    uri: process.env.MONGO_URI ?? 'mongodb://localhost:27017/bookings',
  },
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev_secret_change_me',
    expires: process.env.JWT_EXPIRES ?? '1d',
  },
});
