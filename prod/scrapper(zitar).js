var LIST_CATS, _, cheerio, copyImg, db, encoding, fs, path, path_root, request, sqlite, url_root;

request = require('request');

cheerio = require('cheerio');

fs = require('fs');

path = require('path');

sqlite = require('sqlite3');

db = new sqlite.Database('./zitar.db');

db.run("CREATE TABLE IF NOT EXISTS tovar ( id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT, src TEXT, category TEXT )");

encoding = require('encoding');

_ = require('underscore');

url_root = 'http://www.zitar.ru';

LIST_CATS = ["Гвозди", "Дюбель", "Болты"];

path_root = './img2';

copyImg = function(url, fileName, callback) {
  var r;
  if (!fs.existsSync(fileName)) {
    r = request(url).pipe(fs.createWriteStream(fileName));
    return r.on('close', callback);
  } else {
    return console.log(fileName + ' already exists');
  }
};

request({
  url: url_root,
  encoding: null
}, function(err, response, data) {
  var $;
  if (!fs.existsSync(path_root)) {
    fs.mkdirSync(path_root);
  }
  data = encoding.convert(data, 'utf-8', 'windows-1251');
  $ = cheerio.load(data);
  return $('.mt_rr a').filter(function(i, el) {
    var linkCat, path_cat, titleCat;
    titleCat = $(this).text();
    linkCat = $(this).attr('href');
    if (_.contains(LIST_CATS, titleCat)) {
      path_cat = path_root + "/" + titleCat;
      if (!fs.existsSync(path_cat)) {
        fs.mkdirSync(path_cat);
      }
      return request({
        url: linkCat,
        encoding: null
      }, function(err, response, data) {
        data = encoding.convert(data, 'utf-8', 'windows-1251');
        $ = cheerio.load(data);
        return $('.pti a').filter(function(i, el) {
          var linkItem;
          linkItem = "http://zitar.ru/" + $(this).attr('href');
          return request({
            url: linkItem,
            encoding: null
          }, function(err, response, data) {
            data = encoding.convert(data, 'utf-8', 'windows-1251');
            $ = cheerio.load(data);
            return $('img.tovar').filter(function(i, el) {
              var ext, fileName, srcImg, srcImgLocal, titleImg;
              titleImg = ($(this).attr('title')).trim();
              srcImg = url_root + $(this).attr('src');
              ext = path.extname(srcImg);
              fileName = path_cat + '/' + titleImg + ext;
              srcImgLocal = '/' + titleCat + '/' + titleImg + ext;
              return copyImg(srcImg, fileName, function() {
                console.log(titleImg + " download success");
                return db.run("INSERT INTO tovar(title, src, category) VALUES (?,?, ?)", titleImg, srcImgLocal, titleCat);
              });
            });
          });
        });
      });
    }
  });
});
