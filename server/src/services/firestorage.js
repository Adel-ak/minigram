const { admin } = require("../utils");
const shortid = require("shortid");

exports.uploadToFS = async (file, path = "") => {
    const bucket = admin.storage().bucket();
    const fileName = `${path}${shortid()}-${file.filename}`;
    const ffs = bucket.file(fileName);

    const writeStream = ffs.createWriteStream({
        configPath: fileName,
        public: true,
        private: false,
        metadata :{
            contentType: file.mimetype,
        }
    });

    const postImage = file.createReadStream();

    const result = new Promise((resolve, reject) => {
        writeStream.on('error', function (err) {
            reject(err);
        });

        writeStream.on('finish',  async () => {	
            await ffs.makePublic();
            const url = ffs.publicUrl();
            resolve(url);
        });
    });

    postImage.pipe(writeStream);
    
    return result;
}