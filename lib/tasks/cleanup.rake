#
# CLEANUP tasks
#
# Removing data that has become invalid.
#
# In an ideal world these would not be necessary. If you run any of these and
# they actually do sth. you probably want to find out why and remove the cause.
#

namespace :cg do
  namespace :cleanup do
    desc "Run all cleanup tasks"
    task all: [
      :remove_dead_participations,
      :remove_dead_federatings,
      :remove_lost_memberships,
      :remove_empty_posts
    ]

    desc "Remove all participations where the entity does not exist anymore"
    task(:remove_dead_participations => :environment) do
      count = UserParticipation.where(dead_entity_sql('user')).delete_all
      count += UserParticipation.where(dead_entity_sql('page')).delete_all
      puts "Removed #{count} User Participations."
      count = GroupParticipation.where(dead_entity_sql('group')).delete_all
      count += GroupParticipation.where(dead_entity_sql('page')).delete_all
      puts "Removed #{count} Group Participations."
    end

    desc "Remove all federatings where the group does not exist anymore"
    task(:remove_dead_federatings => :environment) do
      count = Federating.where(dead_entity_sql('group')).delete_all
      puts "Removed #{count} Federatings with outdated groups."
      count = Federating.where(dead_entity_sql('network', 'groups')).delete_all
      puts "Removed #{count} Federatings with outdated networks."
    end

    desc "Remove all federatings where the group does not exist anymore"
    task(:remove_lost_memberships => :environment) do
      count = Membership.where(dead_entity_sql('group')).delete_all
      puts "Removed #{count} Memberships with outdated groups."
    end

    def dead_entity_sql(type, table = nil)
      table ||= type + 's';
      "#{type}_id NOT IN (SELECT id FROM #{table})"
    end

    desc "Remove empty posts"
    task(:remove_empty_posts => :environment) do
      puts "Deleting all empty posts"
      count = Post.where(body: nil).delete_all
      count += Post.where(body: '').delete_all
      puts "Removed #{count} empty posts"
    end

=begin

under development

    desc "Merge duplicate tags"
    task(:merge_dup_tags => :environment) do
      puts "Merging duplicate tags"
      map = ActsAsTaggableOn::Tag.
        joins("JOIN tags AS dup ON tags.name = dup.name").
        where("dup.id > tags.id").
        select("dup.*, tags.id AS target")
    end


    desc "Remove all empty groups with duplicate names"
    task(:remove_empty_duplicate_groups => :environment) do
      puts "Deleting newer empty group duplicates."
      new_dups = duplicates.where("other_group.id < groups.id")
      destroy_empty_groups(new_dups)
      puts "Deleting older empty group duplicates."
      early_dups = duplicates.where("other_group.id > groups.id")
      destroy_empty_groups(early_dups)
    end

    def duplicates
      Group.joins("JOIN groups as other_group ON other_group.name = groups.name")
    end

    def destroy_empty_groups(query)
      puts "Found #{query.count} duplicate groups."
      query.each do |group|
        destroy_if_empty(group)
      end
      puts "#{query.count} duplicate groups left."
    end

    def destroy_if_empty(group)
      return if group.users.count > 1
      return if group.pages.any?
      return if group.version > 1
      group.send(:destroy)
    end

=end
  end
end
