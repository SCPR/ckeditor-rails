require 'thor'

class SourceFile < Thor
  include Thor::Actions
  source_root 'tmp'

  desc 'fetch VERSION', 'fetch source files from http://ckeditor.com/'
  def fetch source_file
    in_root do
      if File.exist? source_file
        FileUtils.mkdir_p source_root
        extract source_file, source_root
        FileUtils.rm_rf source_file
      end
    end
  end

  desc 'move', 'move source files'
  def move
    FileUtils.rm_rf destination_root
    copy_files_in_source_root
    copy_langs
    copy_plugins
    copy_skins
  end

  desc 'fix_css', 'fix some css caused precompilation error'
  def fix_css
    self.destination_root = 'vendor/assets/stylesheets/ckeditor'
    inside destination_root do
      gsub_file 'skins/moono/dialog_iequirks.css',  /\{filter\:\}/, '{}'
    end
  end

  desc 'clean', 'clean up useless files'
  def cleanup
    FileUtils.rm_rf source_root
  end

  protected

  def extract file_path, output_path
    system "tar -x -f '#{file_path}' -C '#{output_path}' ckeditor"
  end

  def copy_files_in_source_root
    [
      ['js', 'javascripts'],
      ['css', 'stylesheets'],
      ['md', 'javascripts'],
    ].each do |(type, asset_path)|
      batch_copy '.', type, asset_path, "*.#{type}"
    end
  end

  def copy_langs
    directory 'ckeditor/lang', 'javascripts/ckeditor/lang'
  end

  def copy_plugins
    Dir["#{source_root}/ckeditor/plugins/*"].each do |plugin|
      path = "plugins/#{File.basename plugin}"
      copy_assets path
      batch_copy path, 'html', 'javascripts'
      batch_copy path, 'md', 'javascripts'
    end
    # ckeditor.js would lookup 'plugins/icons.png'
    file = 'ckeditor/plugins/icons.png'
    copy_file file, "images/#{file}"
  end

  def copy_skins
    Dir["#{source_root}/ckeditor/skins/*"].each do |skin|
      copy_assets "skins/#{File.basename skin}"
    end
  end

  def copy_assets path
    batch_copy path, 'css', 'stylesheets'
    batch_copy path, 'js', 'javascripts'
    batch_copy path, 'png', 'images'
    batch_copy path, 'gif', 'images'
    batch_copy path, 'jpg', 'images'
  end

  def batch_copy path, type, asset_path, pattern = nil
    pattern ||= "#{path}/**/*.#{type}"
    files = Dir["#{source_root}/ckeditor/#{pattern}"]
    files.each do |file|
      file.sub! /^#{Regexp.escape source_root}\//, ''
      copy_file file, "#{asset_path}/#{file}"
    end
  end

  def source_root
    self.class.source_root
  end
end
