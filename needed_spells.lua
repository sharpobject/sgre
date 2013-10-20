function needed_spells()
  print("ANDREW BROZ")
  for k,v in pairs(id_to_canonical_card) do
    if k>=200000 and k<210000 then
      if not rawget(spell_func,k) then
        print(k)
      end
    end
  end
end
