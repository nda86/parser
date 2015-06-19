var cheerio, encoding, request;

request = require('request');

cheerio = require('cheerio');

encoding = require('encoding');

request({
  url: 'http://www.zitar.ru/prod/65/catalog.html',
  encoding: null
}, function(err, res, data) {
  var $;
  data = encoding.convert(data, 'utf-8', 'windows-1251');
  $ = cheerio.load(data);
  return $('.pti a').filter(function(i, el) {
    var link;
    return link = $(this);
  });
});
