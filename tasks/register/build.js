module.exports = function (grunt) {
	grunt.registerTask('build', [
		'clean:build',
    'concat:coffee',
    'jst:dev',
    'jade:dev',
    'sass:build',
		'copy:build',
    'coffee:build',
    'uglify:build',
    'update_json:bower',
    'update_json:manifest',
    'crx:build'
	]);
};
