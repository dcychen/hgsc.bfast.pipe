class SEA_remove
  def initialize
  end

  def run(params)
    perform_remove(params[:sea], params[:c_design], params[:special_run])
  end

  private

  def perform_remove(sea, c_design, special_run)
    # A. Try to find dir
    #    Bail out: dir not found -- no SEA
    Helpers::log "Checking if SEA is already there ..."
    sea_dirs_found = Helpers::dir_exists?(sea, special_run)

    sea_dir = ""
    if sea_dirs_found.size > 1
      Helpers::log("More than 1 sea dir found (#{sea_dirs_found.size})", 1)
    elsif sea_dirs_found.size == 0
      Helpers::log("SEA dir not found", 1)
    else
      sea_dir = Helpers::a_dir_for(sea, special_run)
      Helpers::log "SEA dir found : #{sea_dirs_found[0]}"
    end

    # B. Look for jobs for that SEA and kill them
    Helpers::log "Killing cluster jobs"

    # C. Remove the dir
    puts Helpers::kill_jobs_for(sea)
    puts Helpers::remove_dir(sea_dirs_found[0])
    Helpers::log "Done."
  end
end
