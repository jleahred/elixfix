defmodule  FTags  do
@moduledoc """
Functions to work and convert tags atom, int, string


* atom -> int
* atom -> string
* int -> atom
"""

@external_resource  Path.join(__DIR__, "tags.txt")
#@tag_file Path.join(__DIR__, "tags.txt")
@tag_atom File.stream!(@external_resource)
    |> Stream.map(fn(line)  ->  List.to_tuple(String.split(line)) end)
    |> Stream.map(fn({stag, satom}) ->
            {elem(Integer.parse(stag), 0),
            String.to_atom("#{satom}"),
            satom} end)










for {tag_int, atom, _} <- @tag_atom  do
  def  get_atom(unquote(tag_int))  do
      unquote(atom)
  end
end


@doc """
Convert from int to atom


    iex> FTags.get_atom(8)
    :BeginString


If tag is not known, it will return the received integer
"""
def  get_atom(unknown)  do
    unknown
end








for {tag_int, atom, tag_name} <- @tag_atom  do
  def  get_name(unquote(atom))  do
      unquote("#{tag_name}(#{tag_int})")
  end
end




@doc """
Convert from atom to string


    iex> FTags.get_name(:BeginString)
    "BeginString(8)"


If atom is not know, it will return  atom->string
"""
def get_name(unknown) do
    "#{unknown}"
end










for {tag_int, atom, _} <- @tag_atom  do
  def  get_num(unquote(atom))  do
      unquote(tag_int)
  end
end




@doc """
Convert from atom to int


    iex> FTags.get_num(:BeginString)
    8


If atom is not known, it will return 0
"""
def get_num(_unknown) do
  0
end






end
