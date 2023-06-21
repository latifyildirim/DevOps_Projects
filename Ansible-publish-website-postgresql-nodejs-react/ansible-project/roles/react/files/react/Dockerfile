#FROM node:14
WORKDIR /app
COPY package*.json ./
RUN yarn install
COPY . .
EXPOSE 3000
CMD ["yarn", "run", "start"]

# FROM node:14

# # Create app directory
# WORKDIR /app


# COPY package*.json ./

# RUN yarn install

# # copy all files into the image
# COPY . .

# EXPOSE 3000

# CMD ["yarn", "run", "start"]