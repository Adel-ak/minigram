const DataLoader = require('dataloader');
const { admin } = require('../utils');

const userLoader = new DataLoader(keys => getUsers(keys),);

const getUsers = async (keys) => {
    try {
        const temp = new Map();
        const { users } = await admin.auth().getUsers(keys);

        return keys.map(({ uid }) => {
            if (temp.has(uid)) {
                return temp.get(uid);
            } else {
                const userIndex = users.findIndex((user) => user.uid === uid);
                const userObj = {
                    uid: users[userIndex].uid,
                    displayName: users[userIndex].displayName,
                    email: users[userIndex].email,
                    avatar: users[userIndex].photoURL,
                };
                temp.set(uid, userObj);
                return userObj;
            }
        });
    } catch (error) {

    }
}


exports.userLoader = userLoader