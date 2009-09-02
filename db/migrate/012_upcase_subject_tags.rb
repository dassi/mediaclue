class UpcaseSubjectTags < ActiveRecord::Migration
  def self.up
    SUBJECT_SELECTIONS.each do |subject|
      unless subject.blank?
        tag = Tag.find_by_name(subject)
        tag.update_attribute(:name, subject) unless tag.nil?
      end
    end
  end

  def self.down
    SUBJECT_SELECTIONS.each do |subject|
      unless subject.blank?
        tag = Tag.find_by_name(subject)
        tag.update_attribute(:name, ActiveSupport::Multibyte::Handlers::UTF8Handler.downcase(subject)) unless tag.nil?
      end
    end
  end
end
