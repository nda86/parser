var gulp = require('gulp'),
	rename = require('gulp-rename'),
	jsmin = require('gulp-jsmin'),
	coffee = require('gulp-coffee'),
	gutil = require('gulp-util');


gulp.task('coffee', function(){
	gulp.src("./dev/**/*.coffee")
	.pipe(coffee({bare: true}).on('error', gutil.log))
	//.pipe(jsmin())
	//.pipe(rename({suffix: '.min'}))
	.pipe(gulp.dest("./prod"))
});

gulp.task('watch',function(){
	gulp.watch('./dev/**/*.coffee', ['coffee'])
});

gulp.task('default',['coffee','watch']);