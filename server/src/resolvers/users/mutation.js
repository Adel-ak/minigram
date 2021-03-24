const { catchAsync, admin } = require("../../utils");
const {uploadToFS} = require('../../services/firestorage');

exports.signUp = catchAsync(async (_, { form }, ctx) => {
    const {avatar, ...signUpForm} = form;

    await admin.auth().createUser(signUpForm);   
   
    return true;
});

