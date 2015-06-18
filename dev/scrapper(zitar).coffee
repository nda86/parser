request = require('request') # для запросов по url
cheerio = require('cheerio')# для парсинка html
fs = require('fs')# для работы с файловой системой
path = require('path')# для работы с путями, в том числе и с url

# для работы с кодировками, особенно для перекодирования всякого дерьма типа windows-1251 в нормальную пацанскую кодировку utf-8, ёпта
encoding = require('encoding')
_ = require('underscore')# швейцарский нож для js

# собственно сам донор
url_root = 'http://www.zitar.ru'
# массив с необходимымми категориями
LIST_CATS = [
	"Гвозди",
	"Дюбель", 
	"Болты"
]
# рутовая папка для фоток
path_root = './img2'
# функция скчивания картинки
copyImg = (url, fileName, callback) ->
	# если картнки нет то запрашиваем её request'ом и передаём через pipe в writable stream
	if !fs.existsSync(fileName)
		r = request(url).pipe(fs.createWriteStream(fileName))
		# по окончании скачивания вызываем callback
		r.on('close', callback)
	else
		# если фотка есть уже то просто выводим сообщение об этом в консоль
		console.log fileName + ' already exists'
# parsing main page
request url: url_root, encoding: null, (err, response, data) ->
	if !fs.existsSync path_root
		fs.mkdirSync path_root
	data = encoding.convert data, 'utf-8', 'windows-1251'
	$ = cheerio.load data
	# перебираем все ссылки категорий
	$('.mt_rr a').filter (i, el) ->
		titleCat = $(@).text()
		linkCat = $(@).attr 'href'
		# находим необходимые катогерии
		if _.contains LIST_CATS, titleCat
			path_cat = path_root + "/" + titleCat
			#создаём папку для каждой категории
			if !fs.existsSync path_cat
				fs.mkdirSync path_cat
				# запрашиваем страницу с категорией
			request url: linkCat, encoding: null, (err, response, data) ->
				data = encoding.convert data, 'utf-8', 'windows-1251'
				$ = cheerio.load data
				# находим все ссылки на товары
				$('.pti a').filter (i,el) ->
					linkItem = "http://zitar.ru/" + $(this).attr('href');
					# запрашиваем страницу с товаром
					request url: linkItem, encoding: null, (err, response, data) ->
						data = encoding.convert data, 'utf-8', 'windows-1251'
						$ = cheerio.load data
						# находим картинку на странице с товаром
						$('img.tovar').filter (i, el) ->
							# получаем название картинки-товара
							titleImg = ($(@).attr('title')).trim()
							# получаем ссылку на картинку
							srcImg = url_root + $(@).attr('src')
							# определяем расширение картинки по его url
							ext = path.extname srcImg
							# компонуем путь для локальной(сохранённой) картинки
							fileName = path_cat + '/' + titleImg + ext
							# вызываем ф-ию скачивания картинки
							copyImg srcImg, fileName, ->
								console.log titleImg + " download success"

