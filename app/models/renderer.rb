require 'diff'
require_dependency 'models/wiki_reference'
 
class StubSlot < WagnHelper::Slot
 def slot
 end
end

class Renderer                
  include HTMLDiff
  include ReferenceTypes
  attr_accessor :render_xml

  def render( card, content=nil, update_references=false)
    # FIXME: this means if you had a card with content, but you WANTED to have it render 
    # the empty string you passed it, it won't work.  but we seem to need it because
    # card.content='' in set_card_defaults and if you make it nil a bunch of other
    # stuff breaks
    content = content.blank? ? card.content_for_rendering  : content 
    wiki_content = WikiContent.new(card, content, self, @render_xml)
    update_references(card, wiki_content) if update_references
    wiki_content.render! 
  end

  def render_diff( card, content1, content2 )
    diff( self.render( card, content1), self.render(card, content2) )
  end

  def replace_references( card, old_name, new_name )
    content = content.blank? ? card.content_for_rendering  : content 
    wiki_content = WikiContent.new(card, content, self, @render_xml)

    wiki_content.find_chunks(Chunk::Link).each do |chunk|
      link_bound = chunk.card_name == chunk.link_text          
      chunk.card_name.replace chunk.card_name.replace_particle(old_name, new_name)
      chunk.link_text = chunk.card_name if link_bound
    end
    
    wiki_content.find_chunks(Chunk::Transclude).each do |chunk|
      chunk.card_name.replace chunk.card_name.replace_particle(old_name, new_name)
    end

    String.new wiki_content.unrender!  
  end
      
  protected

#  def common_processing( card, content=nil, update_references=false)
#    raise "Renderer.render() requires card" unless card
#    if @render_stack.plot(:name).include?( card.name )
#      raise Wagn::Oops, %{Circular transclusion; #{@render_stack.plot(:name).join(' --> ')}\n}
#    end
#    @render_stack.push(card)      
#    # FIXME: this means if you had a card with content, but you WANTED to have it render 
#    # the empty string you passed it, it won't work.  but we seem to need it because
#    # card.content='' in set_card_defaults and if you make it nil a bunch of other
#    # stuff breaks
#    content = slot.render_as_xml ?
#                card.xml_content_for_rendering :
#                card.content_for_rendering if content.blank?
#
#    wiki_content = WikiContent.new(card, content, self, slot.render_as_xml)
#    yield wiki_content if block_given?
#    update_references(card, wiki_content) if update_references
#    @render_stack.pop
#    wiki_content
#  end  
  
  def root_card
    @render_stack[0]
  end
  
  def current_card
    @render_stack[-1]
  end
  
  def update_references(card, rendering_result)
    WikiReference.delete_all ['card_id = ?', card.id]
    
    if card.id and card.respond_to?('references_expired')
      card.connection.execute("update cards set references_expired=NULL where id=#{card.id}") 
    end

    rendering_result.find_chunks(Chunk::Reference).each do |chunk|
      reference_type = 
        case chunk
          when Chunk::Link;       chunk.refcard ? LINK : WANTED_LINK
          when Chunk::Transclude; chunk.refcard ? TRANSCLUSION : WANTED_TRANSCLUSION
          else raise "Unknown chunk reference class #{chunk.class}"
        end
      WikiReference.create!(
        :card_id=>card.id,
        :referenced_name=>chunk.refcard_name.to_key, 
        :referenced_card_id=> chunk.refcard ? chunk.refcard.id : nil,
        :link_type=>reference_type
      )
    end
  end
end


