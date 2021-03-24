const { catchAsync, admin } = require("../../utils");

exports.getPosts = catchAsync(async (_, {startAt = null}, ___) => {
    const posts = admin.firestore().collection('posts');
    const lastDoc = startAt ? await (await posts.where('_id','==', startAt).get()).docs[0] : null;    
    const orderedBy = posts.orderBy('createdDate','desc');
    const snapShots = lastDoc ? orderedBy.startAfter(lastDoc) : orderedBy;
    const data = (await snapShots.limit(11).get()).docs.map(doc =>  ({
        ...doc.data(),
        createdDate: doc.data().createdDate.toDate()
    }));

    return data;
});

exports.getUserPosts = catchAsync(async (_, {uid = null, startAt = null}, ___) => {    
    const posts = admin.firestore().collection('posts');
    const where = uid ? posts.where('uid', '==', uid) : posts;
    const snapShots = await where.orderBy('createdDate','desc')
    .get();
    const data = snapShots.docs.map(doc => {
        return {
            ...doc.data(),
            createdDate: doc.data().createdDate.toDate()
        }
    });
    
    return {
        
        posts: data
    };
});
