class HomeController < ApplicationController
  def index
    @classes = 'home '
    if current_user.nil? && !cookies['new_ballot_visitor'] && params['q'].nil?

      cookies['new_ballot_visitor'] = {
        :value => true,
        :expires => 2.weeks.from_now
      }      
      @config = { :state => 'splash' }.to_json
      @classes += 'splash'

      render :template => 'home/splash.html.erb'
    else
      params['q'] = params['q'] || params['address']
      @config = { :address => params['q'].gsub('+',' ') }.to_json unless params['q'].nil?
      render :template => 'home/index.html.erb' 
    end
  end
  
  def about
    @classes = 'home msg'
    @config = { :state => 'page' }.to_json
    @title = 'About'
    @content = <<EOF
         <h1>About TheBallot.org</h1>
         <p>TheBallot.org is the 100% social voter guide brought to you by the <a href='http://www.theleague.com/splash'>League of Young Voters</a>, <a href='http://www.neweracolorado.org'>New Era Colorado</a>, <a href='http://forwardmontana.org'>Forward Montana</a>, and the <a href='http://busproject.org'>Bus Project</a>.</p>
         <p>Some cool stuff about TheBallot.org:</p>
         <ul>
          <li>This is a crowdsourced voter guide. The content and order in which it appears is determined by the wisdom of the masses, not by political powerbrokers.</li>
          <li>This is open-source software. Our commitment to crowdsourcing doesn't stop with ballot measures. We've built this software open source so that others can modify and improve it. Want to check it out? <a href='http://github.com/busproject/ballot' target='_blank'>Here's our GitHub repo</a> - fork away! Want to help? Let us know.</li> 
          <li>We're also utilizing and supporting the Voter Information Project so that other similar projects can piece together the relevant and accurate ballot information for free.</li>
          <li>For the latest updates on new features, please <a class="link" target='_blank' href="http://theballot.tumblr.com/">visit our Tumblr</a>.</li>
         </ul>
         <a class='about-button' href='/'>Find Your Ballot</a>

         <h1>Who We Are</h1>
         <p><strong><a href="http://twitter.com/mojowen" target="_blank">Scott Duncombe</a>, Developer</strong></p>
         <!--<p>Scott Duncombe is a native Oregonian, who grew up mostly in Corvallis before going to school at the University of Chicago, studying Chemistry and Political Science. He got involved with democracy and technology while working with the Student Government, eventually becoming the Student Body President. After Chicago, he organized for Obama for America before returning to Oregon, eventually joining the Bus Project to manage technology. The Federation stole him a year later. He also moonlights as a developer for candidates and others.</p>-->
         <p><strong><a href="https://twitter.com/noahmanger" target="_blank">Noah Manger</a>, Designer</strong></p>
         <!--<p>Text about Noah</p>-->
         <p><strong><a href="https://twitter.com/notsterno" target="_blank">Sarah Stern</a></strong></p>
         <!--<p>Sarah bio</p>-->
         <p><strong><a href="https://twitter.com/sampatton" target="_blank">Sam Patton</a></strong></p>
         <p><strong><a href="https://twitter.com/montuckyliberal" target="_blank">Matt Singer</a></strong></p>
         <!--<p>Matt Bio</p>-->         
EOF

    render 'home/show'
  end
  
  def search
    prepped = '%'+params[:term].split(' ').map{ |word| word.downcase }.join(' ')+'%'
    results = []

    # Stripping profile down to it's root and converting to base 16 to convert into ID. If the base 16 doesn't match the search term - ignore it
    id = params[:term].gsub(ENV['BASE'],'').gsub(root_path,'').to_i(16).to_s(16) == params[:term].gsub(ENV['BASE'],'').gsub(root_path,'') ? params[:term].gsub(ENV['BASE'],'').gsub(root_path,'').to_i(16).to_s(10).to_i(2).to_s(10) : 0

    if params[:filter]
      results += User.where( "id = ? OR profile = ?", id, params[:term] ).limit(20).map{ |user| {:label => user.name, :url => ENV['BASE']+user.profile } } if params[:filter] == 'profile'
    else
      prepped = '%'+params[:term].split(' ').map{ |word| word.downcase }.join(' ')+'%'
      results = []
      results += User.where( "deactivated = ? AND banned = ? AND (lower(name) LIKE ? OR lower(last_name) LIKE ? OR lower(first_name) LIKE ? OR id = ?)",false,false, prepped, prepped, prepped, id ).limit(20).map{ |user| {:label => user.name, :url => ENV['BASE']+user.profile } }
      results += Choice.where( "lower(contest) LIKE ?", prepped).limit(20).map{ |choice| {:label => choice.contest+' ('+choice.geographyNice+')', :url => ENV['BASE']+'/'+choice.to_url } }
      results += Option.where( 'lower(name) LIKE ?',prepped).limit(20).map{ |option| { :label => option.name+' ('+option.choice.geographyNice+')', :url => ENV['BASE']+'/'+option.choice.to_url } }
    end
    render :json => results
  end
  
end
