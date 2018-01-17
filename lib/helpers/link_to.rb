module LinkTo
  def time_zone_link(agenda)
    date = agenda.fetch(:date)
    %(https://www.timeanddate.com/worldclock/fixedtime.html?#{date.strftime('msg=%F')}+SCWG+WG4+Weekly+Call&#{date.strftime('iso=%Y%m%dT%H%M')})
  end
end
