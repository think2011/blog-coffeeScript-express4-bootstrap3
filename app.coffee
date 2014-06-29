express        = require 'express'
fs             = require 'fs'
path           = require 'path'
favicon        = require 'static-favicon'
cookieParser   = require 'cookie-parser'
session        = require 'express-session'
flash          = require 'connect-flash'
bodyParser     = require 'body-parser'

# 路由引用
MongoStore   = require('connect-mongo')(session)
settings     = require './settings'

# 调试引用
logger  	   = require 'morgan'
debug   	   = require('debug')('blog')
accessLog    = fs.createWriteStream 'access.log', flags: 'a'
errorLog     = fs.createWriteStream 'error.log', flags: 'a'
app 		     = express()


app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'ejs'

app.use flash()
app.use favicon()
app.use logger('dev')
app.use logger {stream: accessLog}
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use cookieParser()
app.use session(
  secret: settings.cookieSecret
  cookie: maxAge: 1000 * 60 * 60 * 24 * 30
  store : new MongoStore url: settings.url
)
app.use express.static(path.join(__dirname, 'public'))


# 路由入口
routes  = require './routes/index'
routes(app)

# 写入错误日志
app.use (err, req, res, next) ->
  meta = "[#{new Date()}] - #{req.url}\n"
  errorLog.write "#{meta + err.stack}\n"

# 输出404
app.use (req, res, next) ->
  err = new Error('找不到页面')
  err.status = 404
  next(err)



# 开发环境输出500
if app.get('env') is 'development'
  app.use (err, req, res, next) ->
    status = err.status or 500
    err.status = status

    res.status status
    res.render 'error',
      message: err.message
      error: err


# 输出500
app.use (err, req, res, next) ->
  status = err.status or 500
  err.status = status

  res.status status
  res.render 'error',
    message: err.message
    error: {}

app.set 'port', process.env.PORT || 3000
server = app.listen(app.get('port'), ->
  console.log 'Express 正在监听端口：' + server.address().port
)

module.exports = app


