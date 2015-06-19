# для запросов по url
request = require('request')

# для парсинка html
cheerio = require('cheerio')

encoding = require('encoding')

request url: 'http://www.zitar.ru/prod/65/catalog.html', encoding: null, (err, res, data)->
	data = encoding.convert data, 'utf-8', 'windows-1251'
	$ = cheerio.load data
	$('.pti a').filter (i, el) ->
		link = $(@)
		# console.log link.parentNode()


  #   console.log(link.parent().parent().next().find('a').text());
  #   console.log(link.parent().parent().next().next().find('a').text());
  #   console.log(link.parent().parent().next().next().next().text());