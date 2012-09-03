class ChoiceController < ApplicationController
  def json_include
    return :include => [ 
    :options => { 
      :include => [
        :feedbacks => {
            :include => [ :user => { :except => [ :banned, :admin, :deactivated, :alerts, :created_at, :last_name, :modified_at, :fb_friends, :first_name, :guide_name, :description  ] } ]
          }
        ] 
      }
    ]
  end
  
  def profile
    @user = User.find( params[:id].to_i(16).to_s(10).to_i(2).to_s(10) )

    @choices = @user.choices.each{ |c| c.prep current_user }
    @classes = 'profile home'
    @title = @user.guide_name.nil? || @user.guide_name.empty? ? @user.name+'\'s Voter Guide' : @user.guide_name
    @type = 'Voter Guide'
    @message = @user.description.nil? ? 'A Voter Guide by '+@user.first_name+', powered by The Ballot'  : @user.description
    @image = @user.memes.last.nil? ? nil : meme_show_image_path( @user.memes.last.id )+'.png'

    result = {:state => 'profile', :user => @user }

    @config = result.to_json
    @choices_json = @choices.to_json( json_include )

  end
  
  def show
    @choice = Choice.find_by_geography_and_contest(params[:geography],params[:contest].gsub('_',' '))

    raise ActionController::RoutingError.new('Not Found') if @choice.nil?

    @classes = 'home single'
    @title = @choice.contest
    @partial = @choice.contest_type.downcase.index('ballot').nil? ? 'candidate' : 'measure'
    @type = @partial == 'candidate' ? 'Elected Office' : 'Ballot Measure'
    @message = @type == 'measure' ? @choice.contest.description : 'An election for '+@choice.contest+' between '+@choice.options.map{|o| o.name+'('+o.party+')' }.join(', ')

    result = {:state => 'single', :choices => [ @choice ].each{ |c| c.prep current_user } }

    @config = result.to_json( json_include )

  end

  def index
    
    districts = params['q'].nil? ? Cicero.find(params['l'], params[:address] ) : params['q'].split('|')
    
    unless districts.nil?
      @choices = Choice.find_all_by_geography( districts ).each{ |c| c.prep current_user }
    else
      query = {'success' => false, 'message' => 'Nothing useful was posted'}.to_json
    end
    
    render :json => @choices.to_json( json_include )
  end

  def more
    choice = Choice.find_by_id(params[:id])
    @feedback = choice.more( params[:page], current_user )
    render :json => @feedback
  end
end
