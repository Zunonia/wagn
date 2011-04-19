class Renderer
  define_view(:naked, :type=>'setting') do
    %{<div class="instruction">#{
      expand_inclusions "{{+*right+*edit help}}"} </div>#{

     Wagn::Pattern.subclasses.reverse.each do |set_class|
       key = set_class.key
       %{<h2 class="values-for-setting">#{ key=='*all' ? '*all' : "+#{key}"}</h2>#{
       subrenderer(Card::Search.new(:name=>UUID.new.generate,
         :content=>%{{"left":{"type":"Set","#{key=='*all' ? 'name' : 'right'}":"#{key}"},
                  "right":"#{card.name}","sort":"name","limit":"100"}} # {{, "left_plus":{"right":"*type"}}}
         )).render :content}}
     end * "\n"}}
  end

  define_view(:closed_content, :type=>'setting') do
    %{<div class="instruction">#{expand_inclusions "{{+*right+*edit help}}"}</div>}
  end
end
