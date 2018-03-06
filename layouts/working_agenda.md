# SCWG WG4: Enabling Technologies and Infrastructures Weekly Meeting

Date: <%= @item.fetch(:meeting_time).to_date.to_s(:long) %>

Participants:

Text Chat: CommonsPatterns Slack [#tech-meetings channel][#tech-meetings]
([invite]), or in this doc.

<% previous_index = previous_index_for(@item) %>
<% if previous_index && notes_for(previous_index) %>
Agenda and meeting notes from last call: <%= short notes_for(previous_index).fetch(:alternate_link) %>

<% end %>
Recording of this call:

Transcript of this call:

<%= yield %>

---

[#tech-meetings]: https://commonspatterns.slack.com/messages/C6V6AAEUF/
[invite]: https://limitless-island-44565.herokuapp.com/
