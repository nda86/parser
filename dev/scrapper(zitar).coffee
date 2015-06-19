# для запросов по url
request = require('request')

# для парсинка html
cheerio = require('cheerio')

# для работы с файловой системой
fs = require('fs')

# для работы с путями, в том числе и с url
path = require('path')

# для работы с кодировками, особенно для перекодирования всякого дерьма 
#типа windows-1251 в нормальную пацанскую кодировку utf-8, ёпта
encoding = require('encoding')

# швейцарский нож для js
_ = require('underscore')

# модуль для работы с БД Sqlite3
sqlite = require('sqlite3')


###
необходимые константы
###

# кодировки
encodeFrom = 'windows-1251'
encodeTo = 'utf-8'

# собственно сам донор
url_root = 'http://www.zitar.ru/'

# массив с необходимымми категориями
LIST_CATS = [
	"Гвозди",
	"Дюбель", 
	"Болты"
]

###
Работа с БД
###

# загружаем файл бд
db = new sqlite.Database('./zitar.db')

# создаём таблицу в бд
db.run "CREATE TABLE IF NOT EXISTS tovar 
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		title TEXT,
		gost TEXT,
		src TEXT,
		description TEXT,
		category TEXT
	)"


# рутовая папка для фоток
path_root = './img2'
if !fs.existsSync path_root
	fs.mkdirSync path_root

###
мои вспомогаетльные функции
###

# фнукция загрузки страницы по данному url и далбнейшее постойка дерева в переменную $
curl = (url, cb) ->
	request url: url, encoding: null, (err, response, data) ->
		# если есть ошибка при запросе стр, то кидаем err в cb
		return cb err if err
		data = encoding.convert data, encodeTo, encodeFrom
		$ = cheerio.load data
		cb null, $


# функция скачивания картинки
copyImg = (url, fileName, callback) ->
	# если картнки нет то запрашиваем её request'ом и передаём через pipe
	# в writable stream
	if !fs.existsSync(fileName)
		r = request(url).pipe(fs.createWriteStream(fileName))
		# по окончании скачивания вызываем callback
		r.on('close', callback)
	else
		# если фотка есть уже то просто выводим сообщение об этом в консоль
		console.log fileName + ' already exists'



###
собсно сам процесс парсинга
###

# parsing main page
curl url_root, (err, $)->
	return console.log err if err
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
			curl linkCat, (err, $)->
				return console.log err if err
				# находим все ссылки на товары
				$('.pti a').filter (i,el) ->
					# пляшем от найденной ссылки на страницу конкретного товара
					link = $(@)
					#  находим название товара
					titleItem = link.parent().parent().next().find('a').text()
					# находим ГОСТ товара
					gostItem = link.parent().parent().next().next().find('a').text()
					# находим описание товара
					descriptionItem = link.parent().parent().next().next().next().text()
					# находи ссылку на кртинку товара(маленькая)
					srcImgSmall = link.find('img').attr('src')
					# делаем ссылку на большую картинку
					srcImgBig = url_root + srcImgSmall.replace(/\b\./, 'b\.')
					# определяем расширение картинки по его url
					ext = path.extname srcImgBig
					#предварительно приводим srcImage к относительному
					srcImgLocal = '/' + titleCat + '/' + titleItem + ext
					# строим путь для сохранения картинки
					pathImgLocal = path_root + srcImgLocal
					copyImg srcImgBig, pathImgLocal, ->
						console.log titleItem + " download success"
						# после успешного скачивания фотки
						# добавляем в бд title, src, category, 
						db.run "INSERT INTO tovar(title, gost, src, description, category) 
						VALUES (?,?,?,?,?)", titleItem, gostItem, srcImgLocal, descriptionItem, titleCat
