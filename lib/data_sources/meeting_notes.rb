Class.new(Nanoc::DataSource) do
  identifier :meeting_notes

  def up
    @notes = Dir['var/cache/meeting_notes/*.yaml'].map { |doc| YAML.load_file(doc) }
  end

  def items
    @notes.map { |doc| doc_to_item(doc) }
  end

  def doc_to_item(doc)
    meeting_date = doc.fetch(:title)[/([0-9]{4}-[0-9]{2}-[0-9]{2})/]
    attributes = {
      kind: 'meeting-notes',
    }

    new_item(
      '', # not including the doc content for now
      doc.merge(attributes),
      Nanoc::Identifier.new("/#{meeting_date}/notes"),
      checksum_data: "id=#{doc[:id]},version=#{doc[:version]}")
  end
end
