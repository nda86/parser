var LIST_CATS, _, cheerio, copyImg, curl, db, encodeFrom, encodeTo, encoding, fs, path, path_root, request, sqlite, url_root;

request = require('request');

cheerio = require('cheerio');

fs = require('fs');

path = require('path');

encoding = require('encoding');

_ = require('underscore');

sqlite = require('sqlite3');


/*
необходимые константы
 */

encodeFrom = 'windows-1251';

encodeTo = 'utf-8';

url_root = 'http://www.zitar.ru/';

LIST_CATS = ["Гвозди", "Дюбель", "Болты"];


/*
Работа с БД
 */

db = new sqlite.Database('./zitar.db');

db.run("CREATE TABLE IF NOT EXISTS tovar ( id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT, gost TEXT, src TEXT, description TEXT, category TEXT )");

path_root = './img2';

if (!fs.existsSync(path_root)) {
  fs.mkdirSync(path_root);
}


/*
мои вспомогаетльные функции
 */

curl = function(url, cb) {
  return request({
    url: url,
    encoding: null
  }, function(err, response, data) {
    var $;
    if (err) {
      return cb(err);
    }
    data = encoding.convert(data, encodeTo, encodeFrom);
    $ = cheerio.load(data);
    return cb(null, $);
  });
};

copyImg = function(url, fileName, callback) {
  var r;
  if (!fs.existsSync(fileName)) {
    r = request(url).pipe(fs.createWriteStream(fileName));
    return r.on('close', callback);
  } else {
    return console.log(fileName + ' already exists');
  }
};


/*
собсно сам процесс парсинга
 */

curl(url_root, function(err, $) {
  if (err) {
    return console.log(err);
  }
  return $('.mt_rr a').filter(function(i, el) {
    var linkCat, path_cat, titleCat;
    titleCat = $(this).text();
    linkCat = $(this).attr('href');
    if (_.contains(LIST_CATS, titleCat)) {
      path_cat = path_root + "/" + titleCat;
      if (!fs.existsSync(path_cat)) {
        fs.mkdirSync(path_cat);
      }
      return curl(linkCat, function(err, $) {
        if (err) {
          return console.log(err);
        }
        return $('.pti a').filter(function(i, el) {
          var descriptionItem, ext, gostItem, link, pathImgLocal, srcImgBig, srcImgLocal, srcImgSmall, titleItem;
          link = $(this);
          titleItem = link.parent().parent().next().find('a').text();
          gostItem = link.parent().parent().next().next().find('a').text();
          descriptionItem = link.parent().parent().next().next().next().text();
          srcImgSmall = link.find('img').attr('src');
          srcImgBig = url_root + srcImgSmall.replace(/\b\./, 'b\.');
          ext = path.extname(srcImgBig);
          srcImgLocal = '/' + titleCat + '/' + titleItem + ext;
          pathImgLocal = path_root + srcImgLocal;
          return copyImg(srcImgBig, pathImgLocal, function() {
            console.log(titleItem + " download success");
            return db.run("INSERT INTO tovar(title, gost, src, description, category) VALUES (?,?,?,?,?)", titleItem, gostItem, srcImgLocal, descriptionItem, titleCat);
          });
        });
      });
    }
  });
});
