const { catchAsync, admin } = require("../../utils");
const shortid = require('shortid');
const moment = require('moment');

exports.createPost = catchAsync(async (_, args, { user }) => {
    const doc = await admin.firestore().collection('posts').add({
        _id: shortid(),
        uid: user.uid,
        ...args.form,
        createdDate: moment().local(),
    });

    const data = (await doc.get()).data();

    return data
});

exports.deletePost = catchAsync(async (_, { docId }, { user }) => {
    const doc = await admin.firestore().collection('posts')
    .where('_id', '==', docId)
    .where('uid', '==', user.uid).get();
    
    if(doc.docs[0]){
        doc.docs[0].ref.delete();
        return true
    }

    return false
});

